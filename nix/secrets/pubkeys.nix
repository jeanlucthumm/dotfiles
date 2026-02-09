rec {
  desktop = {
    ssh = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP66W+zH1wVKLB/fXdWF5VIHR5ggphdRMtWzd26uL7I3";
    # TODO: at cutover, secrets.nix switches from desktop.ssh to desktop.age
    age = "age1yubikey1qghw2ekp6tcdxfjd6f43pz5dzwd3v6vlvpha38edtmw78ampyeglznchv5m";
    fido2 = {
      signing = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIJEk+rWWR5oECawCCbJ6o4PQGFFztMKVJhTQcY8cIodlAAAAD3NzaDpnaXQtc2lnbmluZw== desktop-git-signing";
      auth = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAICh5QifgMvLbp0kG2l/0VCqolwMcZHa55MouJVb+oZLKAAAACHNzaDphdXRo desktop-ssh-auth";
    };
  };

  macbook = {
    ssh = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPKSY9ngqsMwi97aC1GM6gTnChfUl22aXzE9wzt0TXJB";
    age = "age1yubikey1qgnp293pa8mn6l8kls4scm88t73mf5cy5vc5g6e2mpk3wj5shvl5vm72q8y";
  };

  phone = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILASMv9zSPwIF9ihPRdzHCZSgYec9P2PlVceItWMjhuO";
  server = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIXzzsAaXcrCbDTYz4Yhv7D9rpkqnxI3qmBimZcEW1Pi";
  all = [desktop.ssh macbook.ssh phone];
}
