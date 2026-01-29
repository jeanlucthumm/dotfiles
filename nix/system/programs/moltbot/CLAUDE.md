# Moltbot Configuration

Personal AI assistant running as a NixOS system service on server.

## Directory Structure

```
moltbot/
├── default.nix     # Main service configuration
├── skills/         # Custom skills (SKILL.md files)
│   └── <name>/
│       └── SKILL.md
└── documents/      # Optional: AGENTS.md, SOUL.md, TOOLS.md
```

## Adding Skills

Skills can be added inline in Nix or as files:

**File-based (preferred for complex skills):**
```nix
services.moltbot.skills = [{
  name = "journal";
  mode = "copy";
  source = ./skills/journal;
}];
```

**Inline:**
```nix
services.moltbot.skills = [{
  name = "quick-skill";
  description = "A simple skill";
  mode = "inline";
  body = ''
    Skill instructions here...
  '';
}];
```

## Skill File Format

Skills use markdown with YAML frontmatter:

```markdown
---
name: skill-name
description: What this skill does
---

# Skill instructions here
```

## References

- Use case spec: ~/nix/mdfiles/moltbot.md
- nix-moltbot repo: ~/Code/nix-moldbot
- Module options: `manix moltbot --source nixos_options`
- Community skills: https://github.com/VoltAgent/awesome-moltbot-skills
  - 700+ skills across 28 categories (dev tools, PKM, smart home, etc.)
  - Good reference for skill format and ideas

## Deployment

Moltbot runs on server.lan. After changes:
```nu
deploy .#server
```
