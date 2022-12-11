# Util functions for interacting with OS
from typing import List
import distro
import platform
import subprocess
import re

INSTALL_RE = re.compile(r"^((f?)\((\w+)\))?([a-zA-Z0-9_]+)")


def platform_installer() -> List[str]:
    sys = platform.system()
    if sys == "Linux":
        dist = distro.id()
        if dist == "arch":
            return ["pacman", "--noconfirm", "-S", "--needed"]
        elif dist == "ubuntu" or dist == "debian":
            return ["apt", "-y", "install"]
        else:
            raise Exception(f"Unknown distribution: '{dist}'")
    else:
        raise Exception(f"Unkown platform: '{sys}'")


def platform_csv_pos() -> int:
    sys = platform.system()
    if sys == "Linux":
        dist = distro.id()
        if dist == "arch":
            return 0
        elif dist == "ubuntu" or dist == "debian":
            return 1
        else:
            raise Exception(f"Unknown distribution: '{dist}'")
    else:
        raise Exception(f"Unkown platform: '{sys}'")


def secondary_installer(id: str) -> List[str]:
    if id == "cargo":
        return ["cargo", "install"]
    elif id == "luarocks":
        return ["luarocks", "install"]
    else:
        raise Exception(f"Unknown secondary installer: {id}")


class InstallSpec:
    def __init__(self, name: str) -> None:
        m = INSTALL_RE.match(name)
        if m is None:
            raise Exception(f"Invalid install spec: {name}")
        self.fallback = m.group(2) is not None
        self.installer = m.group(3)
        if m.group(4) is None:
            raise Exception(f"Invalid install spec: {name}")
        self.package = m.group(4)
        if self.fallback and self.installer is None:
            raise Exception(f"No fallback installer specified for {name}")

    def __str__(self) -> str:
        fallback = "f" if self.fallback else ""
        installer = ("(" + self.installer + ")") if self.installer is not None else ""
        return f"{fallback}{installer}{self.package}"


def install(spec: InstallSpec) -> bool:
    args = []
    fallback_args = []
    if spec.installer is not None:
        fallback_args = secondary_installer(spec.installer)
        fallback_args.append(spec.package)
        if not spec.fallback:
            args = fallback_args
    if len(args) == 0:
        args = platform_installer()
        args.append(spec.package)
    p = subprocess.run(args)
    if p.returncode != 0:
        if spec.fallback:
            p = subprocess.run(fallback_args)
            if p.returncode != 0:
                return False
        return False
    return True


def mock_run(args):
    print(args)
    return type("", (object,), {"returncode": 0})()


if __name__ == "__main__":
    subprocess.run = mock_run
    install(InstallSpec("package"))
    install(InstallSpec("f(cargo)package"))
    install(InstallSpec("(luarocks)package"))
