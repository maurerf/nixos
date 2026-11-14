# Domain docs

[Knowledge index](../README.md)

How agent skills (Matt Pocock's `domain-modeling`, `grilling`, `code-review`
and others) consume and extend this repository's domain documentation. The
repository is single-context.

## Before exploring, read these

- **`CONTEXT.md`** at the repository root: the glossary of domain terms
  (Workstation, host names and so on). It does not exist yet; `domain-modeling`
  creates it the first time a term is resolved. Until then, proceed silently.
- **[Decisions](../decisions.md)**: this repository's decision log, used instead
  of `docs/adr/`. Read the entries that touch the area you are working in.
- The rest of the [knowledge index](../README.md) as the task needs.

## Recording decisions

When a skill would write an ADR (hard to reverse, surprising without context
and the result of a real trade-off), add a dated entry under
**Continuing decisions** in [decisions](../decisions.md) instead, with the
reason and a link to the issue or ticket that holds the detail. Do not create
`docs/adr/`. Decisions that fail any of the three tests stay in their ticket.
