Cut:

- Code with no concrete reason: unused params, exports, flags, fallbacks,
  branches for impossible states, checks the types already prove.
- Speculative performance machinery (caches, memoization, their metrics):
  remove it when its only consumer is already cached. Otherwise ask in the
  report, naming the evidence that would settle it (hit rate, cost of the
  uncached path). Don't improve it.
- A catch that swallows into a default in trusted code, where the failure
  can't occur.
- Thin wrappers and one-use indirection. Tiny helpers don't get their own file.
- Reinvention: go find the existing helper, library, named type, or constant.
- Type escapes (`any`, casts, suppressions) dodging a real type.
- Comments that restate the code, narrate history or migration, cite PR plans,
  other files, vendors, or examples. A future reference becomes a one-line
  TODO. Gloss a term once, at module or type level, not on every symbol.
- Debug residue and commented-out code.
- Tests that run no production code (they check their own fixtures), once
  you've named what still covers the path.
- In model-facing text: commands ("Do not", "Never") where describing the
  situation would do.

Keep, because cleanup passes reliably get these wrong:

- Why-comments: purpose, domain terms, why something is required, where a
  magic number or config name comes from, where an invariant is enforced.
  Shorten, never drop the fact. Existing reader-facing docstrings are
  presumed intentional.
- Lenient parsing of model or user input, and error accumulation (don't turn
  it into early returns).
- Guards that fail loudly on real states: loop bounds, boundary validation,
  logs or metrics on rare paths.
- Catches at trust boundaries (network, model or user input): flag them,
  don't remove.
- Abstractions that encode a known axis of variation.
- Model-facing text that explains what will happen.
- Pragmas, public API, anything tooling consumes.
