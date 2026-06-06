# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Go Code Guidelines

### Style and Organization

- **Imports**: Standard library first, third-party and project imports second, any renamed imports last
- **Naming**: Package names lowercase single word; types follow Go export conventions
- **Types**: Use strong typing for domain concepts; interfaces for services
- **Comments**: Explain intent using godoc style; document complex operations. AVOID comments that verbatim explain the code beneath them
- **Organization**: Group methods by functionality; helpers at bottom of file
- Use `any` instead of `interface{}`
- Prefer `slog` over `fmt.Print*`

### Error Handling

- Default to `fmt.Errorf`, especially for internal errors
- Provide error context that doesn't stutter (avoids e.g. "could not ... ", "failed to", "unable to")
  when wrapping and includes only information the callee wouldn't have. Use gerunds for actions
  (e.g. "building SQL query" instead of "failed to build SQL query")
- Avoid `err := ...`, i.e. declaring err if it's the only thing on the left. Prefer `if err := ...; err != nil {}`. If `...` is too long/multi-line, consider factoring out params into variables

### Debugging

- When fixing build errors or checking documentation for Go types/methods, use `go doc` command directly:
  - Example: `go doc google.golang.org/protobuf/types/known/fieldmaskpb.FieldMask.Normalize`
- After big changes, do a `go build ./...`
