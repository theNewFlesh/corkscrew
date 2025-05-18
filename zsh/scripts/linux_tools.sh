# requires: batcat, gnome-shell, spd-say, telnet, vscode, xsel

if [[ `uname` == "Linux" ]]; then
    bindkey '^[[1;3C' forward-word       # alt-right
    bindkey '^[[1;3D' backward-word      # alt-left
    bindkey '^[[1;5C' end-of-line        # ctrl-right
    bindkey '^[[1;5D' beginning-of-line  # ctrl-left

    alias pbcopy="xsel -i -b"
    alias restart-gnome-shell="killall -USR2 gnome-shell"
    alias say="spd-say -y 'en-us' -p -90 -r -20"
    alias star-wars="telnet towel.blinkenlights.nl"
    alias vscode="/snap/bin/code"
fi;
