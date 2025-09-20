# Templates

Files meant to "instantiate" something.

## Using Nix Templates

### Listing Available Templates
```bash
# List templates from this flake
nix flake show --json | jq '.templates'

# Or with a simpler view
nix flake show
```

### Initializing a Template
```bash
# Initialize a template in the current directory
nix flake init -t /path/to/flake#template-name

# Initialize from a remote flake
nix flake init -t github:user/repo#template-name

# Initialize from the current flake (when in the repo)
nix flake init -t .#template-name
```

### Common Commands
```bash
# Copy template to a new directory
nix flake new my-project -t .#template-name

# Show template metadata
nix flake metadata .#templates.template-name

# Initialize with a specific template from nixpkgs
nix flake init -t nixpkgs#templates.rust
```

### Example Usage
```bash
# If this repo has a 'basic' template
nix flake init -t .#basic

# Create a new project from template
nix flake new ~/projects/my-app -t .#basic
```
