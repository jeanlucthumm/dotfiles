# A script for fast boot strapping

import os
import sys
import subprocess
from pathlib import Path


def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)


def env_var(var: str) -> str:
    r = os.environ.get(var)
    if r is None:
        eprint(f"Could not get required env variable {var}")
        sys.exit(-1)
    return r


def cmd(*c: str) -> subprocess.CompletedProcess:
    return subprocess.run(list(c), check=False)


class CommandChain:
    failed: bool
    command: str

    def __init__(self):
        self.failed = False

    def __call__(self, *c) -> bool:
        return self.cmd(*c)

    def cmd(self, *c: str) -> bool:
        if self.failed:
            return False
        ret = cmd(*c)
        if ret.returncode != 0:
            self.failed = True
            self.command = str(c)
            return False
        return True

    def cd(self, directory: str):
        os.chdir(Path(directory))

    def check(self) -> bool:
        if self.failed:
            eprint(f"Command failed: {self.command}")
            return False
        return True


STEP_FILE = Path(env_var("CONFIG")) / "yadm/step_file.txt"


class Task:
    def getName(self):
        raise NotImplementedError

    def run(self):
        raise NotImplementedError

    def undo(self):
        raise NotImplementedError


class Yay(Task):
    def getName(self):
        return "yay"

    def run(self) -> bool:
        c = CommandChain()
        c("sudo", "/usr/bin/pacman", "-S", "--needed", "git", "base-devel")
        c("git", "clone", "https://aur.archlinux.org/yay.git")
        c.cd("yay")
        c("makepkg", "-si")
        c.cd("..")
        c("rm", "-rf", "yay")
        return c.check()


def main():
    y = Yay()
    y.run()


if __name__ == "__main__":
    main()
