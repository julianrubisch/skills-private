# Build Notes

Things to remember when distilling import material into actual skills.
Not content — instructions for the skill-building phase.

## Frontend

- Review agents should defer to `hwc-*` skills for Stimulus/Turbo mechanics —
  do not duplicate that content in jr-rails agents
- Coding skills (`37signals`, `phlex`) cover the Rails-side integration only;
  the `## Frontend` section in each import file contains those notes
- When building coding skills, include a pointer: "for frontend patterns, invoke
  the relevant hwc-* skill alongside this one"
- `37signals` style pairs with: `hwc-stimulus-fundamentals`, `hwc-navigation-content`,
  `hwc-realtime-streaming`, `hwc-forms-validation`, `hwc-ux-feedback`
- `phlex` style pairs with: same hwc skills + any Phlex-specific component patterns
  from the import file

## Symlink Reminder

Skills are not yet symlinked into `~/.claude/skills/`. Do this after the first
skill is built and functional, not before.
