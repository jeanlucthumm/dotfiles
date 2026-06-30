# Nix Configuration and dotfiles for Jean-Luc

Config for all my systems.

## TL;DR

A flake-parts, dendiritic based configuration with the following modules:

- **base** — Baseline usable config. Includes stuff like CLI, but relatively barebones
- **dev** – Adds configs for development. Meant for daily use
- **graphical** – For daily machines with a GUI
- **secrets** — For machines with a hwkey that are able to unlock and use repo secrets
- **theme** — Themeing via stylix and custom
- **homeServer** — For headless server managing a home

All modules in [`./autoimport`](./autoimport).

## How the config comes together

Assuming no background knowledge, here's me trying to explain piece by piece:

### What are modules?

Nix itself is just a functional programming language that operates on attribute sets, also known
as "attrs", also known as fancy JSON with semicolons, which have _options_ (i.e. fields) on them.

A nix config is just a really large attrs that fully describes the state of your system (host).

But you don't write out the entire attribute set yourself, in one file.
Instead we describe everything as _functions_.

Each of these functions take in a config (an attrs), optionally look into it for relevant info, and then output that same config
while guaranteeing that the options they care about are set. For example, imagine that our config contains:

```nix
{
  monitor = {
    enable = true;
    manufacturer = "asus";
  };
}
```

A function might declare that if `monitor.enable` is true, and we have `monitor.manufacturer` set to `"asus"`,
then the config _should also set_ `drivers.asus.enable = true`. So the output of the function is:

```nix
{
  monitor = {
    enable = true;
    manufacturer = "asus";
  };
  drivers.asus.enable = true;
}
```

These functions are of course **NixOS modules**.

Now, another module might declare that if `drivers.asus.enable` is true, then we should have a
`system.activationScripts` entry to configure the Asus driver, and so on. In this way,
modules form a web of dependencies where their output configs affect each others input configs,
and their input configs translate to more output configs.

> [!TIP]
> The role of the NixOS module system evaluator is to find the **fixpoint** of the collection of all modules

The [fixpoint](<https://en.wikipedia.org/wiki/Fixed_point_(mathematics)>) is the point `x` in a function
`f` where `f(x) = x`.

In the NixOS module system, `x` is the config, and `f` is all of our modules. So we have, all equivalent:

- The evaluator is finding the config (attribute set) where the input matches the output for all modules ==
- The fixpoint is the config where all modules agree there's nothing to change ==
- The fixpoint is the config which satisfies all requirements

### There's more than one fixpoint (config)

A flake will usually define multiple hosts. Each one of those hosts is a fixpoint. So you might have a few nixos ones, a few darwin ones, etc.
All those come from one evaluation of modules each.

Home manager config is a different fixpoint! It's synergetic to the overall system config, but it gets attached per user and evaluated seperately.

### So what is flake-parts?

Flake-parts asks a big question: what if we applied the NixOS module system to the flake itself?

So you end up with multiple layers of configs:

flake -> systems (nixos/darwin/...) -> home manager

Each are a seperate set of modules evaluated to sepereate configs. That's why you hear the new term
"flake modules".

### Dendritic pattern, i.e. an inverted model

Flake parts is usable on its own, but this repo has a cooler pattern layered on top.

Traditionally, we bundle up modules hierarchically: you make a low level module for e.g. fish, then you import it into a CLI module,
and the CLI module into a dev module, which then gets imported into your host. Sometimes even more layers in between.

The key realization is that you don't _need_ all this abstraction, and you get better mileage by inverting it:

> [!TIP]
> Instead of top level modules importing lower level modules, lower modules directly contribute to top modules

See an example [here](./autoimport/modules/tailscale.nix). Notice how we just add to the `base`
module for NixOS, and there's no explicit definition of `base` which imports `tailscale.nix`.

Then at the very end, hosts import only a select few top level modules.
