"""`t2i "a prompt"`: text to image from the terminal, through ComfyUI's HTTP API.

Uses the ComfyUI already running on :8188, or starts one for the duration of
the command. Prints the path of each image it saved.
"""
import argparse
import json
import os
import random
import subprocess
import sys
import time
import urllib.error
import urllib.request

URL = "http://127.0.0.1:8188"


def call(path, body=None):
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(URL + path, data=data, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)


def running():
    try:
        call("/system_stats")
        return True
    except OSError:
        return False


# FLUX 3 Klein, distilled, uncompressed: 16 steps and no CFG, as in the
# official workflow. The shift of ln(16) is that workflow's "alpha".
def graph(prompt, width, height, steps, seed):
    def node(class_type, **inputs):
        return {"class_type": class_type, "inputs": inputs}

    return {
        "model": node("UNETLoader", unet_name="flux3-image-klein-bf16.safetensors", weight_dtype="default"),
        "clip": node("CLIPLoader", clip_name="qwen3vl_4b_bf16.safetensors", type="flux3", device="default"),
        "vae": node("VAELoader", vae_name="flux2-vae.safetensors"),
        "positive": node("CLIPTextEncode", clip=["clip", 0], text=prompt),
        "negative": node("CLIPTextEncode", clip=["clip", 0], text=""),
        "latent": node("EmptyFlux2LatentImage", width=width, height=height, batch_size=1),
        "shift": node("ModelSamplingFlux", model=["model", 0], max_shift=2.77259, base_shift=2.77259, width=width, height=height),
        "sample": node(
            "KSampler", model=["shift", 0], positive=["positive", 0], negative=["negative", 0],
            latent_image=["latent", 0], seed=seed, steps=steps, cfg=1.0,
            sampler_name="euler", scheduler="simple", denoise=1.0,
        ),
        "decode": node("VAEDecode", samples=["sample", 0], vae=["vae", 0]),
        "save": node("SaveImage", images=["decode", 0], filename_prefix="t2i"),
    }


def generate(args, seed):
    try:
        prompt_id = call("/prompt", {"prompt": graph(args.prompt, args.width, args.height, args.steps, seed)})["prompt_id"]
    except urllib.error.HTTPError as e:
        sys.exit(f"ComfyUI rejected the request: {e.read().decode()}")
    while prompt_id not in (history := call(f"/history/{prompt_id}")):
        time.sleep(0.5)
    entry = history[prompt_id]
    if entry["status"]["status_str"] != "success":
        errors = [m[1].get("exception_message", "") for m in entry["status"]["messages"] if m[0] == "execution_error"]
        sys.exit("generation failed: " + " ".join(errors).strip())
    data_home = os.environ.get("XDG_DATA_HOME") or os.path.expanduser("~/.local/share")
    for output in entry["outputs"].values():
        for image in output.get("images", []):
            print(os.path.join(data_home, "comfyui", "output", image["subfolder"], image["filename"]), flush=True)


def main():
    parser = argparse.ArgumentParser(prog="t2i", description="Text to image with FLUX 3 Klein through ComfyUI.")
    parser.add_argument("prompt", help="what to draw; full descriptive sentences work best")
    parser.add_argument("--width", type=int, default=1024, help="multiple of 16 (default 1024)")
    parser.add_argument("--height", type=int, default=1024, help="multiple of 16 (default 1024)")
    parser.add_argument("--steps", type=int, default=16)
    parser.add_argument("--seed", type=int, help="fixed seed for the first image (default random)")
    parser.add_argument("-n", "--count", type=int, default=1, help="number of images, each with a new seed")
    args = parser.parse_args()

    server = None
    if not running():
        print("starting ComfyUI...", file=sys.stderr)
        server = subprocess.Popen(["comfyui"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        while not running():
            if server.poll() is not None:
                sys.exit("ComfyUI exited while starting; run `comfyui` to see why")
            time.sleep(1)
    try:
        seed = args.seed if args.seed is not None else random.randrange(2**48)
        for i in range(args.count):
            generate(args, seed + i)
    finally:
        if server is not None:
            server.terminate()
            server.wait()


main()
