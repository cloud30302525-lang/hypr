# ---------------------------------------------------------------------------
# cachyos
# ---------------------------------------------------------------------------
source /usr/share/cachyos-fish-config/conf.d/done.fish
set -U __done_min_cmd_duration 1

# ---------------------------------------------------------------------------
# fastfetch
# ---------------------------------------------------------------------------
function fish_greeting
    command fastfetch
end

# ---------------------------------------------------------------------------
# history
# ---------------------------------------------------------------------------
function history
    builtin history --reverse --show-time='%e-%b-%T '
end

# ---------------------------------------------------------------------------
# symlinks: list (~/.config, ~/.mozilla)
# ---------------------------------------------------------------------------
function lnk --description "List symlinks"
    set broken 0

    for f in (find ~/.config ~/.mozilla -type l 2>/dev/null | sort)
        if test -e $f
            set_color green
            echo "󰌷  $f → "(readlink -f $f)
        else
            set_color red
            echo "󰅚  $f"
            set broken (math $broken + 1)
        end
        set_color normal
    end

    echo "— Broken: $broken"
end

# ---------------------------------------------------------------------------
# symlinks: delete broken
# ---------------------------------------------------------------------------
function lnkd --description "Delete broken symlinks"
    set removed 0

    for f in (find ~/.config ~/.mozilla -xtype l 2>/dev/null)
        rm $f
        echo "󰅚  removed $f"
        set removed (math $removed + 1)
    end

    echo "— Removed: $removed"
end

# ---------------------------------------------------------------------------
# symlinks: add from ~/hyprend → ~/.config
# ---------------------------------------------------------------------------
function lnkadd --description "Link hyprend configs"
    set src ~/hyprend
    set dst ~/.config
    set added 0

    for d in $src/*
        test -d $d; or continue
        set name (path basename $d)
        contains $name rule firefox; and continue

        mkdir -p $dst/$name

        for f in $d/*
            set t $dst/$name/(path basename $f)
            test -e $t; and continue

            ln -s $f $t
            echo "󰌷  $t → $f"
            set added (math $added + 1)
        end
    end

    echo "— Added: $added"
end

# ---------------------------------------------------------------------------
# aliases
# ---------------------------------------------------------------------------
alias mirror  'sudo cachyos-rate-mirrors'
alias grubup  'sudo grub-mkconfig -o /boot/grub/grub.cfg'
alias update  'sudo pacman -Syu'
alias lock    'hyprlock'

alias ls      'eza -a -1 --group-directories-first --icons'
alias j       "expac --timefmt='%e-%b-%T' '%l\t%n %v' | sort | tail -150 | nl"

alias c   'clear'
alias f   'fastfetch'
alias h   'history'
alias q   'paru -S'
alias d   'sudo pacman -Rns'
alias ccc 'paru -Scc'
