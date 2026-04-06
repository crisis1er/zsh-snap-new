# Changelog

All notable changes to this plugin are documented here.

---

## [1.0] — 2026-04-06

### Added
- Initial release — interactive guided snapper snapshot creation for openSUSE Tumbleweed
- `snap-new` — fully interactive prompt: reason, config, type, confirmation, colored feedback
- Config auto-detection — `home` prompt only appears if the config exists
- Type selection: `standard` (timeline cleanup) or `important` (protected from cleanup)
- `--cleanup-algorithm timeline` always applied
- `important=yes` userdata for protected snapshots
- Colored ANSI output throughout (green = standard, yellow = important, red = error)
