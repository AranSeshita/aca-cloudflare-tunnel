---
name: reviewing-docs
description: Review this repository's READMEs (root / per-module) and .tf comments for accuracy, consistency, and conciseness. Use after writing/updating a README, after tidying .tf comments, or as a final check before publishing. Includes cross-checking README Inputs/Outputs tables against variables.tf/outputs.tf, and detecting leftovers from other projects (service_bus / openai / key_vault / renderer, etc.) or stale references.
---

# Documentation review

Scope: root `README.md`, every `modules/*/README.md`, and comments inside `.tf` files.
Report findings concretely as "file, line, problem, suggested fix". Apply fixes when asked.

## Process

Copy this checklist into your reply and track progress against it:

```
- [ ] 1. Read the target files (README plus the corresponding .tf)
- [ ] 2. Cross-check the Inputs/Outputs tables against variables.tf / outputs.tf
- [ ] 3. Collect findings per review criterion
- [ ] 4. Present them in order of severity (apply fixes if requested)
- [ ] 5. For comment-only changes, confirm fmt / validate are unaffected
```

Commands for the cross-check:

```bash
grep -nE "variable|output" modules/<m>/*.tf                 # variable / output names that actually exist
grep -rniE "service_bus|openai|key_vault|renderer|civil\.example|container_registroy" --include="*.md" .  # leftovers from other projects / stale references
```

## Review criteria

### Accuracy (highest priority)

- README Inputs / Outputs tables match `variables.tf` / `outputs.tf` (names, types, defaults, no extras or omissions).
- Code examples (HCL) reference real variable names, module outputs, and source paths (no removed variables or old directory names).
- Procedures (`init` / `plan` / `apply`, values to fill into tfvars) match reality.

### Consistency

- Language: comments and prose are unified in English.
- Structure: every module README follows `Usage` / `Inputs` / `Outputs` / `Notes`.
- Terminology: no mixed spellings for the same concept.
- No leftovers from other projects.

### Conciseness

- Cut redundancy and duplication (one message per item).
- Keep bullet style consistent (noun phrases or full sentences, not a mix).
- Heading hierarchy, tables, and code blocks are intact.

## Output format

```
## <file>
- [Accuracy] L<line>: <problem> → <suggested fix>
- [Consistency] L<line>: ...
```

If there are no findings, state "No issues found" explicitly.
