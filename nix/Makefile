default: rebuild

build:
	nix-build '<nixpkgs/nixos>' -A vm -I nixpkgs=channel:nixos-24.05 -I nixos-config=./configuration.nix

qemu_serial:
	@QEMU_KERNEL_PARAMS=console=ttyS0 ./result/bin/run-nixos-vm -nographic; reset

rebuild:
	sudo cp ./*.nix /etc/nixos/ && sudo nixos-rebuild switch

home_manager:
	systemctl status home-manager-jeanluc
