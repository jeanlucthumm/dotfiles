rec {
  desktop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP66W+zH1wVKLB/fXdWF5VIHR5ggphdRMtWzd26uL7I3";

  # TODO: migrate to YubiKey-backed keys, then remove ssh-ed25519 keys above
  desktopYubikey = "age1yubikey1qghw2ekp6tcdxfjd6f43pz5dzwd3v6vlvpha38edtmw78ampyeglznchv5m";
  macbook = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPKSY9ngqsMwi97aC1GM6gTnChfUl22aXzE9wzt0TXJB";
  phone = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILASMv9zSPwIF9ihPRdzHCZSgYec9P2PlVceItWMjhuO";
  server = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIXzzsAaXcrCbDTYz4Yhv7D9rpkqnxI3qmBimZcEW1Pi";
  all = [desktop macbook phone];
}
