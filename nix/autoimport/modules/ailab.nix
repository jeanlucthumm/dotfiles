# Local AI Lab
fp @ {withSystem, ...}: let
  searxPort = 8889;
in {
  flake.modules.nixos.ailab = {
    pkgs,
    lib,
    ...
  }: let
    # Not the system `pkgs`: see the `nixpkgs-ailab` input in flake.nix. To bump
    # it, take the nixpkgs revision of the latest successful Hydra build of
    # `python3Packages.torchWithRocm`:
    # https://hydra.nixos.org/job/nixpkgs/unstable/python314Packages.torchWithRocm.x86_64-linux/latest
    aipkgs = fp.inputs.nixpkgs-ailab.legacyPackages.${pkgs.stdenv.hostPlatform.system};

    comfyuiRocm = aipkgs.comfyui.override {
      python3 = aipkgs.python3.override {
        packageOverrides = final: prev: {
          # The same derivation as `torchWithRocm`, spelled out because that
          # attribute is `self.torch.override`, so assigning it to `torch`
          # recurses forever.
          torch = prev.torch.override {
            triton = final.triton-no-cuda;
            rocmSupport = true;
            cudaSupport = false;
          };
        };
      };
    };

    # The first two flags work around defects of this ROCm PyTorch build on the
    # RX 7900 XT (gfx1100). Retest without them after bumping `nixpkgs-ailab`.
    #
    # --disable-mmap: uploading weights to the GPU straight from a memory-mapped
    # file stalls about 2s per tensor, which is minutes per model. Reading them
    # into RAM first uploads at over 1 GB/s.
    #
    # --use-split-cross-attention: torch's scaled_dot_product_attention is wrong
    # on the GPU here (all zeros in float32, and FLUX 3's text encoder output is
    # uncorrelated with the CPU's, so images ignore the prompt). ComfyUI's own
    # attention matches the CPU, at about 20% slower sampling.
    #
    # --disable-api-nodes keeps the lab local-only: it removes the nodes that
    # send prompts to paid cloud services, and the web UI skips its version
    # check against api.comfy.org when it sees the flag.
    comfyui = pkgs.writeShellScriptBin "comfyui" ''
      exec ${lib.getExe comfyuiRocm} \
        --disable-mmap --use-split-cross-attention --disable-api-nodes "$@"
    '';
  in {
    environment.systemPackages = [
      comfyui
      # It starts `comfyui` itself when none is running.
      (pkgs.writers.writePython3Bin "t2i" {
          flakeIgnore = ["E501"];
          makeWrapperArgs = ["--prefix" "PATH" ":" (lib.makeBinPath [comfyui])];
        }
        ./_ailab/t2i.py)
      pkgs.python3Packages.huggingface-hub
    ];

    # Local search engine
    services.searx = {
      enable = true;
      settings = {
        server = {
          bind_address = "127.0.0.1";
          port = searxPort;
          limiter = false;
        };
        # The JSON API is off by default, and it is what the MCP server calls.
        search.formats = ["html" "json"];
        # This SearXNG version returns Brave's redirect links as broken URLs.
        engines = [
          {
            name = "brave";
            disabled = true;
          }
        ];
      };
    };
    # SearXNG refuses to start with its default secret key. It only listens on
    # loopback, so the boot ID (which systemd substitutes for %b) is enough,
    # and it keeps a secret out of this public repo.
    systemd.services.searx.environment.SEARXNG_SECRET = "%b";

    home-manager.sharedModules = [fp.config.flake.modules.homeManager.ailab];
  };

  flake.modules.homeManager.ailab = {
    pkgs,
    lib,
    system,
    ...
  }: let
    fpkgs = withSystem system ({config, ...}: config.packages);
    tinfoilPort = 3301;
  in {
    # Models are not declared here: `ollama pull <name>` puts them in ~/.ollama.
    services.ollama = {
      enable = true;
      package = pkgs.ollama-rocm;
      # The context window every model gets unless it sets its own. opencode
      # assumes each model has its full native window (262144 for these) and
      # only compacts near that, while Ollama rejects a prompt longer than what
      # it allocated, so the two must agree. The 9B models fit at this size
      # (15.5 GiB at 4-bit, 18.5 GiB at 8-bit). Unset, a 20 GiB card gets 4k.
      environmentVariables.OLLAMA_CONTEXT_LENGTH = "262144";
    };

    # Tinfoil's endpoint also answers a plain OpenAI client, but then nothing
    # checks that an enclave is on the other end: that check is in Tinfoil's
    # SDKs, which opencode does not use. So opencode talks to this proxy, and
    # the proxy does it. It holds no credential: the API key arrives from
    # opencode with each request.
    systemd.user.services.tinfoil-proxy = {
      Unit.Description = "Attesting proxy to Tinfoil enclaves";
      Service = {
        ExecStart = "${lib.getExe fpkgs.tinfoil-proxy} --port ${toString tinfoilPort}";
        # It exits when it cannot attest an enclave at startup, which is every
        # login that beats the network.
        Restart = "on-failure";
        RestartSec = 10;
      };
      Install.WantedBy = ["default.target"];
    };

    home.sessionVariables = {
      # Keep opencode off its vendor's servers: left alone it polls
      # models.opencode.ai for a model catalog and lists hosted models next to
      # Ollama's.
      OPENCODE_DISABLE_MODELS_FETCH = "true";
      OPENCODE_DISABLE_FREE_MODELS = "true";
    };

    programs.opencode = {
      enable = true;
      # opencode rewrites its own config files when settings change in the
      # TUI, so these go to separate files that it loads through environment
      # variables. Without those variables (a plain `nu -c` over ssh, say),
      # it runs with none of the settings below.
      mutableSettings = true;
      validateFiles = {
        config = true;
        cli = true;
      };
      # Built from the terminal's palette and follows its light/dark
      # switches, so it tracks kitty and `theme-toggle`.
      cli.theme = {
        name = "system";
        mode = "system";
      };
      settings = {
        # opencode finds Ollama's models by itself; this is only the default.
        model = "ollama/ornith-1.5:9b";
        # The catalog bundled with opencode already has a `tinfoil` provider,
        # aimed straight at Tinfoil's servers. This sends it through the proxy
        # instead; without it opencode still works, unattested. The key is not
        # here: `opencode auth login` keeps it in opencode's own database.
        providers.tinfoil = {
          settings.baseURL = "http://127.0.0.1:${toString tinfoilPort}/v1";
          # Tinfoil's strongest coding model, which that catalog does not have
          # yet. Values from https://inference.tinfoil.sh/v1/models.
          models."kimi-k3-1-pro" = {
            name = "Kimi K3.1 Pro";
            limit.context = 262144;
            capabilities = {
              tools = true;
              input = ["text" "image"];
            };
          };
        };
        # The built-in search tool only talks to hosted services.
        websearch = false;
        # The 27B models do not fit at the default window, so each is pinned to
        # 64k in Ollama: a Modelfile of `FROM <name>` and `PARAMETER num_ctx
        # 64000`, applied with `ollama create <name> -f <file>` (pulling the
        # model again undoes it). opencode does not read that parameter, so it
        # is repeated here.
        providers.ollama.models = lib.genAttrs ["qwen3.8:27b" "orcarouter/Qwen3.8-27B-Uncensored:q4_K_S"] (_: {
          limit = {
            context = 64000;
            output = 32000;
          };
        });
        mcp.servers.searxng = {
          type = "local";
          command = [(lib.getExe pkgs.mcp-searxng)];
          environment.SEARXNG_URL = "http://127.0.0.1:${toString searxPort}";
          # Offer the tools to the model directly rather than through
          # opencode's JavaScript `execute` tool.
          codemode = false;
        };
        # opencode allows everything unless told otherwise.
        permissions = [
          {
            action = "shell";
            resource = "*";
            effect = "ask";
          }
          {
            action = "external_directory";
            resource = "*";
            effect = "ask";
          }
        ];
      };
    };
  };
}
