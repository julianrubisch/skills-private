# jr-rails-skills

Personal Rails coding and review skills for Claude Code.

## Status

Work in progress. Import material lives in `import/` and gets compiled into skills.

## Structure

```
import/                      # Raw reference material (fill this in first)
  review-architecture.md
  review-quality.md
  review-testing.md
  review-performance.md
  review-security.md
  coding-37signals.md
  coding-phlex.md
  refactorings/
    000-template.md
    ...
```

## Workflow

1. Fill in the `import/` files with patterns, anti-patterns, heuristics, examples
2. Build skills from import material
3. Symlink skill directories into `~/.claude/skills/`
