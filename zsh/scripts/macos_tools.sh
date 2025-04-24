# requires: bettersnaptool, brave, iterm2, vlc, vscode

source $ZSH_SCRIPTS/variables.sh

if [[ `uname` == "Darwin" ]]; then
    bindkey '^P' kill-line

    bettersnap () {
        # Configure bettersnap settings
        # args: [keyboard or numpad]
        defaults import com.hegenberg.BetterSnapTool $MISC_DIR/bettersnaptool/$1.plist; \
        killproc bettersnap; \
        open /Applications/BetterSnapTool.app; \
    }

    alias cat="bat"
    alias pcat="bat --plain --color never"
    alias xcat="bat --show-all"
    alias bettersnap-keyboard='bettersnap keyboard'
    alias bettersnap-numpad='bettersnap numpad'
    alias brave='/Applications/Brave\ Browser.app/Contents/MacOS/Brave\ Browser'
    alias iterm="/Applications/iTerm.app/Contents/MacOS/iTerm2 &"
    alias vlc='open -n /Applications/VLC.app/Contents/MacOS/VLC'
    alias vscode='/Applications/Visual\ Studio\ Code.app/Contents/MacOS/Electron'
    alias parallel="/usr/local/bin/parallel --no-notice"
fi;
