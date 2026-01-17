#!/usr/bin/env bash
direction="${1:-next}"

# Workspace с окнами
workspaces=($(hyprctl workspaces -j | jq -r '.[] | select(.windows>0) | .id' | sort -n))
[ "${#workspaces[@]}" -eq 0 ] && exit 0

current=$(hyprctl activewindow -j | jq -r '.workspace.id')

# Индекс текущего workspace
current_index=-1
for i in "${!workspaces[@]}"; do
    [[ "${workspaces[$i]}" == "$current" ]] && { current_index=$i; break; }
done

if [ "$current_index" -eq -1 ]; then
    next_workspace="${workspaces[0]}"
else
    if [ "$direction" == "next" ]; then
        next_workspace="${workspaces[$(( (current_index + 1) % ${#workspaces[@]} ))]}"
    else
        next_workspace="${workspaces[$(( (current_index - 1 + ${#workspaces[@]}) % ${#workspaces[@]} ))]}"
    fi
fi

hyprctl dispatch workspace "$next_workspace"
