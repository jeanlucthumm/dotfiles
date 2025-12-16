---
paths: home/programs/nushell/**/*.nu
---

# Nushell Configuration

After editing nushell config files, verify syntax with:

```bash
nu -c 'source <file>'
```

## Pipeline vs Arguments

- **Pipeline input**: The subject being transformed/queried (fits in chains)
- **Named arguments**: Configuration, options, or multiple equal-weight inputs

```nu
# Pipeline: record is the subject, composes naturally
def is-expired []: [record -> bool] { ... }
$items | where ($it | is-expired)

# Arguments: multiple inputs of equal importance
def copy-to [src: path, dest: path] { ... }
copy-to ./a ./b
```
