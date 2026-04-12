# ============================================================
# zsh-snap-new — Oh My Zsh plugin for openSUSE Tumbleweed
# Interactive guided snapper snapshot creation
# Version: 2.1 — 2026-04-12
# ============================================================

# Disable any residual alias that would shadow the function
unalias snap-new 2>/dev/null

# Create a fully interactive guided snapshot
# Features: banner + 2-column scenario table + disk check + context + root/home/both + colored feedback
# Usage: snap-new
function snap-new {
    local RED="\033[31m" GREEN="\033[32m" YELLOW="\033[33m"
    local CYAN="\033[36m" BOLD="\033[1m" RESET="\033[0m"

    # 0. Detect whether sudo is required for snapper
    local -a SNAPPER
    if snapper list-configs &>/dev/null 2>&1; then
        SNAPPER=(snapper)
    else
        SNAPPER=(sudo snapper)
    fi

    # Config validation — check snapper is configured
    local configs
    configs=$("${SNAPPER[@]}" list-configs 2>/dev/null | awk 'NR>2 {print $1}' | tr '\n' ' ')
    if [[ -z "$configs" ]]; then
        echo -e "${RED}No snapper configuration found.${RESET}"
        echo -e "Initialize with: ${BOLD}sudo snapper create-config /${RESET}"
        echo -e "See: https://en.opensuse.org/openSUSE:Snapper_Tutorial"
        return 1
    fi

    # 1. Welcome banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}${BOLD}              Snap-New — SafeITExperts                        ${RESET}${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}              Guided Snapshot Creation                        ${CYAN}║${RESET}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${CYAN}║${RESET}  You are about to create a snapshot of your system.          ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}                                                              ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}  A snapshot captures the current state of your filesystem.   ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}  If something goes wrong, you can roll back to this point.   ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}                                                              ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}  ${YELLOW}→${RESET} Choose ${YELLOW}Important${RESET} if you're about to make a significant    ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}    change (update, install, config, downgrade)               ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}  ${GREEN}→${RESET} Choose ${GREEN}Standard${RESET} for routine checkpoints                   ${CYAN}║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # 2. Reason — 2-column scenario table (7 Important / 7 Standard)
    echo -e "${CYAN}┌───────────────────────────────┬──────────────────────────────┐${RESET}"
    echo -e "${CYAN}│${RESET}${BOLD}${YELLOW}  Important                    ${RESET}${CYAN}│${RESET}${BOLD}${GREEN}  Standard                    ${RESET}${CYAN}│${RESET}"
    echo -e "${CYAN}├───────────────────────────────┼──────────────────────────────┤${RESET}"
    echo -e "${CYAN}│${YELLOW}  1. Before system update      ${CYAN}│${GREEN}  8. Routine checkpoint       ${CYAN}│${RESET}"
    echo -e "${CYAN}│${YELLOW}  2. Before kernel change      ${CYAN}│${GREEN}  9. After successful test    ${CYAN}│${RESET}"
    echo -e "${CYAN}│${YELLOW}  3. Before pkg install/removal${CYAN}│${GREEN} 10. Clean state              ${CYAN}│${RESET}"
    echo -e "${CYAN}│${YELLOW}  4. Before downgrade          ${CYAN}│${GREEN} 11. Weekly snapshot          ${CYAN}│${RESET}"
    echo -e "${CYAN}│${YELLOW}  5. Before config change      ${CYAN}│${GREEN} 12. Monthly snapshot         ${CYAN}│${RESET}"
    echo -e "${CYAN}│${YELLOW}  6. Before migration          ${CYAN}│${GREEN} 13. After update verified    ${CYAN}│${RESET}"
    echo -e "${CYAN}│${YELLOW}  7. Security update           ${CYAN}│${GREEN} 14. Before testing           ${CYAN}│${RESET}"
    echo -e "${CYAN}└───────────────────────────────┴──────────────────────────────┘${RESET}"
    echo -e "     ${CYAN}0.${RESET}  Custom — type your own reason\n"
    printf "Choice [0-14] : "
    read -r reason_choice

    local desc smart_default="s"
    case "$reason_choice" in
        1)  desc="Before system update (zypper dup)";  smart_default="i" ;;
        2)  desc="Before kernel change";               smart_default="i" ;;
        3)  desc="Before pkg install/removal";         smart_default="i" ;;
        4)  desc="Before downgrade";                   smart_default="i" ;;
        5)  desc="Before config change";               smart_default="i" ;;
        6)  desc="Before migration";                   smart_default="i" ;;
        7)  desc="Security update";                    smart_default="i" ;;
        8)  desc="Routine checkpoint";                 smart_default="s" ;;
        9)  desc="After successful test";              smart_default="s" ;;
        10) desc="Clean state";                        smart_default="s" ;;
        11) desc="Weekly snapshot";                    smart_default="s" ;;
        12) desc="Monthly snapshot";                   smart_default="s" ;;
        13) desc="After update verified";              smart_default="s" ;;
        14) desc="Before testing";                     smart_default="s" ;;
        *)
            printf "\n${BOLD}Reason${RESET} : "
            read -r desc
            if [[ -z "$desc" ]]; then
                echo -e "${RED}Error: reason is required${RESET}"
                return 1
            fi
            if echo "$desc" | grep -qiE 'update|upgrade|zypper|before|downgrade|security|kernel|migration'; then
                smart_default="i"
            fi
            ;;
    esac

    # 3. Config selection (only if home config exists)
    local config="root"
    if echo "$configs" | grep -q "home"; then
        echo -e "\n${BOLD}Config:${RESET}"
        echo -e "  ${CYAN}(r)${RESET} root"
        echo -e "  ${CYAN}(h)${RESET} home"
        echo -e "  ${CYAN}(b)${RESET} both"
        printf "Choice [r/h/b] (default: r) : "
        read -r cfg_choice
        if [[ "$cfg_choice" =~ ^[hH]$ ]]; then
            config="home"
        elif [[ "$cfg_choice" =~ ^[bB]$ ]]; then
            config="both"
        else
            config="root"
        fi
    fi

    # 4. Disk space check (warn if > 85%)
    local usage
    usage=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
    if [[ "$usage" -gt 85 ]]; then
        echo -e "\n${YELLOW}⚠ Warning: disk usage is ${usage}% — creating a snapshot may worsen space pressure${RESET}"
        printf "Continue anyway? [y/N] : "
        read -r space_confirm
        if [[ ! "$space_confirm" =~ ^[yY]$ ]]; then
            echo -e "${YELLOW}Cancelled.${RESET}"
            return 0
        fi
    fi

    # 5. Context: snapshot count + last snapshot per config (CSV parsing)
    local -a target_configs
    if [[ "$config" == "both" ]]; then
        target_configs=(root home)
    else
        target_configs=($config)
    fi

    echo -e "\n${BOLD}Current state:${RESET}"
    for cfg in "${target_configs[@]}"; do
        local csv_data count last_line last_id last_type last_date last_desc_ctx last_userdata
        local last_status last_status_color

        # CSV — fields: $1=number $2=type $3=date $4=description $5=userdata
        csv_data=$("${SNAPPER[@]}" -c "$cfg" --csvout --separator '|' --no-headers list \
            --columns number,type,date,description,userdata 2>/dev/null)

        if [[ -z "$csv_data" ]]; then
            echo -e "  ${CYAN}${cfg}${RESET} — ${RED}config not found or no snapshots${RESET}"
            continue
        fi

        count=$(echo "$csv_data" | grep -c '|')
        last_line=$(echo "$csv_data" | tail -1)
        last_id=$(echo "$last_line"       | awk -F'|' '{print $1}')
        last_type=$(echo "$last_line"     | awk -F'|' '{print $2}')
        last_date=$(echo "$last_line"     | awk -F'|' '{print $3}')
        last_desc_ctx=$(echo "$last_line" | awk -F'|' '{print $4}')
        last_userdata=$(echo "$last_line" | awk -F'|' '{print $5}')

        if echo "$last_userdata" | grep -q "important=yes"; then
            last_status="important"; last_status_color="$YELLOW"
        else
            last_status="standard";  last_status_color="$GREEN"
        fi

        echo -e "  ${CYAN}${cfg}${RESET} — ${count} snapshot(s) — last: #${last_id} \"${last_desc_ctx}\" [${last_type}, ${last_status_color}${last_status}${RESET}] (${last_date})"
    done

    # 6. Type selection (smart default based on scenario or keywords)
    echo -e "\n${BOLD}Type:${RESET}"
    echo -e "  ${GREEN}(s)${RESET} Standard  — automatic timeline cleanup"
    echo -e "  ${YELLOW}(i)${RESET} Important — protected from automatic cleanup"
    if [[ "$smart_default" == "i" ]]; then
        echo -e "  ${CYAN}→ Suggested: important (based on selected scenario)${RESET}"
        printf "Choice [s/i] (default: i) : "
    else
        printf "Choice [s/i] (default: s) : "
    fi
    read -r type_choice

    local userdata="" type_label type_color
    if [[ "$type_choice" =~ ^[iI]$ ]] || [[ -z "$type_choice" && "$smart_default" == "i" ]]; then
        userdata="important=yes"
        type_label="important"
        type_color="$YELLOW"
    else
        type_label="standard"
        type_color="$GREEN"
    fi

    # 7. Colored confirmation summary
    echo -e "\n${BOLD}Summary:${RESET}"
    echo -e "  Config  : ${CYAN}${config}${RESET}"
    echo -e "  Type    : ${type_color}${type_label}${RESET}"
    echo -e "  Reason  : ${BOLD}${desc}${RESET}"
    printf "\nConfirm? [y/N] : "
    read -r confirm
    if [[ ! "$confirm" =~ ^[yY]$ ]]; then
        echo -e "${YELLOW}Cancelled.${RESET}"
        return 0
    fi

    # 8. Create snapshot(s) — with exit code check and ID verification
    echo ""
    for cfg in "${target_configs[@]}"; do
        # Get previous last ID via CSV
        local prev_id
        prev_id=$("${SNAPPER[@]}" -c "$cfg" --csvout --separator '|' --no-headers list \
            --columns number 2>/dev/null | tail -1 | tr -d '|')

        local args=(-c "$cfg" create --description "$desc" --cleanup-algorithm timeline)
        [[ -n "$userdata" ]] && args+=(--userdata "$userdata")
        "${SNAPPER[@]}" "${args[@]}"
        local exit_code=$?

        if [[ $exit_code -ne 0 ]]; then
            echo -e "${RED}${BOLD}✗ Failed to create snapshot on [${cfg}] (snapper exit code: ${exit_code}).${RESET}"
            continue
        fi

        # Verify a new snapshot was actually created
        local new_id
        new_id=$("${SNAPPER[@]}" -c "$cfg" --csvout --separator '|' --no-headers list \
            --columns number 2>/dev/null | tail -1 | tr -d '|')

        if [[ "$new_id" == "$prev_id" ]]; then
            echo -e "${RED}${BOLD}✗ Snapshot ID unchanged after creation on [${cfg}] — possible error.${RESET}"
            continue
        fi

        echo -e "${BOLD}${GREEN}✓ Snapshot #${new_id} created${RESET} [${CYAN}${cfg}${RESET}] — ${type_color}${type_label}${RESET} — \"${desc}\" (previous: #${prev_id})"
    done
}
