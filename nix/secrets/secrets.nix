let
  jeanluc = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPKSY9ngqsMwi97aC1GM6gTnChfUl22aXzE9wzt0TXJB"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP66W+zH1wVKLB/fXdWF5VIHR5ggphdRMtWzd26uL7I3"
  ];
in {
  # Define your secrets here
  "jeanluc-openai.age".publicKeys = jeanluc;
  "jeanluc-anthropic.age".publicKeys = jeanluc;
}
