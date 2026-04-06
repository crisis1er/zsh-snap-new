[![Visitors](https://visitor-badge.laobi.icu/badge?page_id=crisis1er.zsh-snap-new)](https://github.com/crisis1er/zsh-snap-new)
![Platform](https://img.shields.io/badge/platform-openSUSE%20Tumbleweed-73BA25)
![Shell](https://img.shields.io/badge/shell-zsh%205.9%2B-blue)
![OMZ](https://img.shields.io/badge/Oh%20My%20Zsh-compatible-red)
![License](https://img.shields.io/badge/license-MIT-green)
![Version](https://img.shields.io/badge/version-v1.0-orange)

# zsh-snap-new

Oh My Zsh plugin for **interactive guided snapper snapshot creation** on openSUSE Tumbleweed — replaces the raw `snapper create` command with a step-by-step prompt: reason, config selection, type, confirmation, and colored feedback.

Deployed and validated on a live openSUSE Tumbleweed system.

---

## Architecture

<sub>⚠️ If the diagram is not visible, refresh the page — Mermaid rendering may take a moment.</sub>

```mermaid
flowchart LR
    classDef plugin  fill:#1e3a5f,stroke:#93c5fd,stroke-width:2px,color:#ffffff
    classDef step    fill:#14532d,stroke:#86efac,stroke-width:2px,color:#ffffff
    classDef confirm fill:#7f1d1d,stroke:#fca5a5,stroke-width:2px,color:#ffffff
    classDef output  fill:#78350f,stroke:#fcd34d,stroke-width:2px,color:#ffffff

    P[zsh-snap-new\nOh My Zsh plugin]:::plugin
    P --> R[Reason\nmandatory input]:::step
    R --> C[Config\nroot / home]:::step
    C --> T[Type\nstandard / important]:::step
    T --> S[Summary\ncolored confirmation]:::confirm
    S --> CR[snapper create\n--cleanup-algorithm timeline]:::output
    CR --> FB[Feedback\nSnapshot #id created]:::output
```

---

## Requirements

- openSUSE Tumbleweed
- zsh 5.9+
- [Oh My Zsh](https://ohmyz.sh/)
- `snapper` — `sudo zypper install snapper`
- Snapper configured with at least one config (`root`, optionally `home`)

---

## Installation

```zsh
git clone https://github.com/crisis1er/zsh-snap-new \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/snap-new
```

Add `snap-new` to the plugins list in `~/.zshrc`:

```zsh
plugins=(... snap-new)
```

Reload:

```zsh
source ~/.zshrc
```

---

## Usage

```zsh
snap-new
```

The function prompts step by step:

```
Reason : before system update

Config:
  (r) root
  (h) home
Choice [rh] (default: r) : r

Type:
  (s) Standard  — automatic timeline cleanup
  (i) Important — protected from automatic cleanup
Choice [si] (default: s) : i

Summary:
  Config  : root
  Type    : important
  Reason  : before system update

Confirm? [y/N] : y

✓ Snapshot #42 created — important — "before system update"
```

---

## Design decisions

- **No argument** — fully interactive, no risk of forgetting the description
- **`--cleanup-algorithm timeline`** always set — snapshots are managed automatically unless marked `important=yes`
- `important=yes` userdata protects the snapshot from automatic cleanup by snapper's number/timeline algorithms
- `function name { }` syntax — prevents zsh alias/function conflicts on shell reload
- Config `home` prompt appears only if the config actually exists on the system
