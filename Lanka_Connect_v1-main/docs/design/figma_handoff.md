# Figma Handoff Freeze

This document tracks the frozen design package used for the Flutter revamp.

## Source
- Figma file: `UI-UX-Revamp-for-Lanka-Connect`
- Freeze date: `2026-02-24`
- Owner: Product/Design

## Required exports
- Color tokens (light + dark)
- Typography tokens
- Spacing and radius scales
- Elevation/shadow specs
- Component states:
  - default
  - hover (web)
  - focus
  - disabled
  - error
  - selected
- Icon set and image assets
- Screen specs for:
  - Seeker mobile
  - Provider mobile
  - Admin web
  - Shared auth/entry screens

## Implementation notes
- Business logic remains unchanged.
- Token bridge files:
  - `lib/ui/theme/design_tokens.dart`
  - `lib/ui/mobile/mobile_tokens.dart`
  - `lib/ui/web/web_tokens.dart`
- Core shell files:
  - `lib/ui/mobile/mobile_page_scaffold.dart`
  - `lib/ui/web/web_shell.dart`
  - `lib/ui/web/web_page_scaffold.dart`

## Asset rules
- Place static exports under `assets/`.
- Use predictable naming (example: `assets/icons/nav_services.svg`).
- Optimize large raster assets before commit.
- Keep semantic icons consistent with role/status states.

## Sign-off checklist
- [ ] Tokens exported and reviewed
- [ ] Components mapped to Flutter equivalents
- [ ] Mobile and web responsive constraints reviewed
- [ ] All states documented (loading, empty, error, locked, not-signed-in)
- [ ] Role permissions verified against current app behavior
