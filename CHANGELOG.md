# Changelog

All notable changes to this plugin are documented here.

---

## [2.1] — 2026-04-12

### Changed
- Auto-detect sudo requirement — uses `snapper` directly if user has access via ALLOW_USERS/ALLOW_GROUPS, falls back to `sudo snapper` otherwise
- Replaced `│`-based parsing with `snapper --csvout` in "Current state" and ID sections — locale-independent
- Config validation at startup — explicit error + initialization instructions if snapper not configured
- Post-creation exit code check — `✓` only shown on actual success
- Verified `new_id != prev_id` — detects silent creation failures
- Fixed confirmation prompts `[yYoO]` → `[yY]` — English only

## [1.0] — 2026-04-06

### Added
- Initial release — interactive guided snapper snapshot creation for openSUSE Tumbleweed
- `snap-new` — fully interactive prompt: reason, config, type, confirmation, colored feedback
- Config auto-detection — `home` prompt only appears if the config exists
- Type selection: `standard` (timeline cleanup) or `important` (protected from cleanup)
- `--cleanup-algorithm timeline` always applied
- `important=yes` userdata for protected snapshots
- Colored ANSI output throughout (green = standard, yellow = important, red = error)
