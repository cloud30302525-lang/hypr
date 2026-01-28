#source /usr/share/cachyos-fish-config/cachyos-config.fish
# notify
source /usr/share/cachyos-fish-config/conf.d/done.fish
set -U __done_min_cmd_duration 1

function fish_greeting
    fastfetch
end

function history
    builtin history --reverse --show-time='%e-%b-%T '
end

function lnk --description "List symlinks in .config and .mozilla"
    for f in (find $HOME/.config $HOME/.mozilla -type l 2>/dev/null | sort)
        test -e $f; or begin
            set_color f38ba8; echo "$f -> BROKEN"; set_color normal; continue
        end
        set t (readlink -f $f)
        set_color (string match -q "$HOME/*" $t; and echo a6e3a1; \
                   or string match -q "/usr/*" $t; and echo 89b4fa; \
                   or echo f9e2af)
        echo "$f -> $t"
        set_color normal
    end
end

function lnkd --description "Remove broken symlinks from .config and .mozilla"
    find $HOME/.config $HOME/.mozilla -xtype l -delete 2>/dev/null
end

function lnkadd
    for d in ~/hyprend/*; test -d $d; or continue
        set n (path basename $d); contains $n rule firefox; and continue
        mkdir -p ~/.config/$n; ln -sf $d/* ~/.config/$n/
    end
end

alias mirror='sudo cachyos-rate-mirrors'
alias grubup='sudo grub-mkconfig -o /boot/grub/grub.cfg'
alias update='sudo pacman -Syu'
alias ls='eza -a -1 --group-directories-first --icons'
alias j="expac --timefmt='%e-%b-%T' '%l\t%n %v' | sort | tail -150 | nl"
alias lock='hyprlock'

alias c='clear'
alias f='fastfetch'
alias h='history'
alias q='paru -S'
alias d='sudo pacman -Rns'
alias ccc='paru -Scc'
