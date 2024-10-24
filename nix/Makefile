default: rebuild

qemu_serial:
	@QEMU_KERNEL_PARAMS=console=ttyS0 ./result/bin/run-nixos-vm -nographic; reset

rebuild:
	sudo nixos-rebuild switch --flake .\#laptop

home_manager:
	sudo systemctl restart home-manager-jeanluc
