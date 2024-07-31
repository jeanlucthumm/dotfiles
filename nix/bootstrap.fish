#!/usr/bin/env nix-shell
#! nix-shell -i bash --pure
#! nix-shell -p bash git

git clone https://github.com/jeanlucthumm/dotfiles /tmp/dotfiles
nixos-rebuild switch --flake /tmp/dotfiles\#laptop
