let
  everyone = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMrAZBawMWs9Mrj0zdH6GqrOOwO/FgkUbiyyhO2O1EP3"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBI2Gy8ax9rmLLwhElUT863UGSN87RUOtSYo0qMfncZA"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFBvN1cJ4mckB7CqrYA5zIIk0R8mN5JQiqNkCNTuxuB0"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINOhEtExFLY53R6RhcPAVHpdMsyn0dt1COeh0Iu7QP4/"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPKSY9ngqsMwi97aC1GM6gTnChfUl22aXzE9wzt0TXJB"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP66W+zH1wVKLB/fXdWF5VIHR5ggphdRMtWzd26uL7I3"
  ];
in {
  # Define your secrets here
  "openai.age".publicKeys = everyone;
  "anthropic.age".publicKeys = everyone;
}
