{lib, ...}: {
  flake.templates =
    lib.attrsets.concatMapAttrs (key: value: {
      ${key} = {
        path = ./_files + "/${key}";
        description = value;
      };
    }) {
      python = "Python devenv";
      go = "Go devenv";
      flutter = "Flutter devenv";
      typescript = "Typescript devenv";
    };
}
