# mcp-language-server: MCP server that exposes language servers to LLMs
#
# USAGE INSTRUCTIONS:
#
# 1. Install a language server for your target language:
#    - Go: `nix-shell -p gopls` or add gopls to your environment
#    - Rust: `nix-shell -p rust-analyzer` or add rust-analyzer to your environment
#    - Python: `nix-shell -p pyright` or add pyright to your environment
#    - TypeScript: `nix-shell -p nodePackages.typescript-language-server` or add to environment
#    - C/C++: `nix-shell -p clang-tools` (provides clangd) or add to environment
#
# 2. Configure your MCP client (e.g., Claude Desktop) in claude_desktop_config.json:
#
# For Go projects:
# {
#   "mcpServers": {
#     "language-server": {
#       "command": "mcp-language-server",
#       "args": ["--workspace", "/path/to/your/go/project", "--lsp", "gopls"],
#       "env": {
#       }
#     }
#   }
# }
#
# For other languages, replace "gopls" with:
#   - Rust: "rust-analyzer"
#   - Python: "pyright-langserver" with args: [..., "--", "--stdio"]
#   - TypeScript: "typescript-language-server" with args: [..., "--", "--stdio"]
#   - C/C++: "clangd" with args: [..., "--", "--compile-commands-dir=/path/to/build"]
#
# 3. Ensure your project workspace has proper configuration files:
#    - Go: go.mod file
#    - Rust: Cargo.toml file
#    - Python: pyproject.toml or requirements files
#    - TypeScript: package.json and tsconfig.json
#    - C/C++: compile_commands.json (generate with cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON)
#
{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "mcp-language-server";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "isaacphi";
    repo = "mcp-language-server";
    rev = "e439584"; # Latest commit from main branch
    sha256 = "sha256-INyzT/8UyJfg1PW5+PqZkIy/MZrDYykql0rD2Sl97Gg=";
  };

  vendorHash = "sha256-WcYKtM8r9xALx68VvgRabMPq8XnubhTj6NAdtmaPa+g=";

  # Only build the main package and the generate command
  subPackages = ["." "cmd/generate"];

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  # Skip tests that require network access or external dependencies
  checkFlags = [
    "-skip=TestIntegration"
  ];

  meta = with lib; {
    description = "MCP server that runs and exposes a language server to LLMs";
    homepage = "https://github.com/isaacphi/mcp-language-server";
    license = licenses.mit; # Based on LICENSE file in repo
    maintainers = [];
    platforms = platforms.all;
    mainProgram = "mcp-language-server";
  };
}
