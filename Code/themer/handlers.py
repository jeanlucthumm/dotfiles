import os
from pathlib import Path
import re
import subprocess
import sys

ERR_UNKNOWN_THEME = "Unknown theme"

HOME = Path(os.environ["HOME"])


class ThemeError(ValueError):
    pass


def search_and_replace(path: str, search: str, replace: str):
    with open(path, "r+") as f:
        text = f.read()
        text = re.sub(search, replace, text, flags=re.MULTILINE)
        f.seek(0)
        f.write(text)
        f.truncate()


def handle_kitty(theme: str):
    if theme not in ["solarized-light", "solarized-dark"]:
        raise ThemeError(ERR_UNKNOWN_THEME)
    path = str(HOME / ".config/kitty/kitty.conf")
    search_and_replace(path, "^include.*$", f"include theme-{theme}.conf")
    search_and_replace(path, "^env.*$", f"env KITTY_THEME={theme}")


def handle_gtk(theme: str):
    if theme == "solarized-light":
        name = "Orchis-light"
        # name = "NumixSolarizedLightBlue"
        icon = "Tela"
        # icon = "WhiteSur-dark"
        dark = "0"
    elif theme == "solarized-dark":
        name = "NumixSolarizedDarkBlue"
        icon = "WhiteSur-dark"
        dark = "1"
    else:
        raise ThemeError(ERR_UNKNOWN_THEME)

    for version in ["gtk-3.0", "gtk-4.0"]:
        path = str(HOME / f".config/{version}/settings.ini")
        search_and_replace(path, "^gtk-theme-name.*$", f"gtk-theme-name={name}")
        search_and_replace(
            path, "^gtk-icon-theme-name.*$", f"gtk-icon-theme-name={icon}"
        )
        search_and_replace(
            path,
            "^gtk-application-prefer-dark-theme.*$",
            f"gtk-application-prefer-dark-theme={dark}",
        )


def handle_wallpaper(theme: str):
    if theme == "solarized-light":
        path = HOME / "media/flower.jpg"
    elif theme == "solarized-dark":
        path = HOME / "media/arch-dark.png"
    else:
        raise ThemeError(ERR_UNKNOWN_THEME)

    subprocess.run(["ln", "-sf", path, str(HOME / ".config/default_wallpaper")])
    subprocess.run(["feh", "--bg-scale", str(path)])


HANDLERS = {
    "kitty": handle_kitty,
    "gtk": handle_gtk,
    "wallpaper": handle_wallpaper
}


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("bad usage")
        exit(127)
    bad_handlers = []
    for key, handler in HANDLERS.items():
        try:
            handler(sys.argv[1])
        except ThemeError:
            bad_handlers.append(key)
    if len(bad_handlers) != 0:
        print(
            f"The following handlers do not support theme {sys.argv[1]}:", bad_handlers
        )
