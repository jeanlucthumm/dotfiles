# Nix Configuration and dotfiles for Jean-Luc

Config for all my systems.

## How the config comes together

Assuming no background knowledge, here's me trying to explain piece by piece:

### What are modules? (and why flake-parts is cool)

Nix itself is just a functional programming language that operates on attribute sets, also known
as "attrs", also known as fancy JSON with semicolons.

A nix config is just a really large attrs that fully describes the state of your system (host).

An evaluator then takes that attrs and makes it real on your system.

TODO
