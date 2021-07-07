import argparse
import re
import subprocess


def printColorRgb(text, r, g, b, background=False):
    print(
        "\033[{};2;{};{};{}m".format(48 if background else 38, r, g, b)
        + text
        + "\033[0m"
    )


def printColorHex(text, hexString):
    hexString = hexString.lower()
    rgb = tuple(int(hexString[i : i + 2], 16) for i in (0, 2, 4))
    printColorRgb(text, rgb[0], rgb[1], rgb[2])


def parseFile(file):
    prog = re.compile(r"^\*([a-zA-z]+[0-9]*): *#([0-9a-zA-z]+)")
    for line in file.split("\n"):
        result = prog.search(line)
        if result is not None:
            printColorHex(f"██████ {result.group(1)}", result.group(2))


DESCRIPTION = "Print all the colors in an .Xresource file"


def main():
    parser = argparse.ArgumentParser(description=DESCRIPTION)
    parser.add_argument("xresource", help="path to xresource file")
    args = parser.parse_args()

    ret = subprocess.run(["cpp", "-P", args.xresource], capture_output=True, text=True)
    parseFile(ret.stdout)


if __name__ == "__main__":
    main()
