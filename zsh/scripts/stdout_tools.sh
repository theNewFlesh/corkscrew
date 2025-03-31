stdout_apply () {
    # Evaluate given command and echo cleaned output to stdout
    # args: command
    local BUFF='';
    while read -r data; do
        BUFF="$BUFF>>nl>>$data";
    done;
    BUFF=$(echo $BUFF | sed -E 's/^>>nl>>//' | sed 's/>>nl>>/\n/g');
    eval "$1 '$BUFF'";
}

stdout_buffer () {
    # Append spaces to each input line until end of terminal buffer
    local WIDTH=`tput cols`;
    while read -r LINE; do
        local DECOLOR=`echo $LINE | stdout_decolor`;
        python3 -c "
import sys
line = sys.argv[1]
decolor = sys.argv[2]
width = int(sys.argv[3])
buff = ' ' * (width - len(decolor) - 1)
print(line + buff + '\x1b[0;0m')
" "$LINE" "$DECOLOR" $WIDTH
    done;
}

stdout_color () {
    # Color text that matches a given regex
    # args: color, regex
    while read -r data; do
        local stdin=`/bin/cat -v <<< "$data"`;
        local found=`echo "$stdin" | grep -E "$2"`;
        if [ "$found" != "" ]; then
            echo "$1$stdin${CLEAR}";
        else
            echo "$stdin";
        fi;
    done;
}

stdout_decolor () {
    # Remove color codes from input text
    while read -r data; do
        /bin/cat -v <<< "$data" | sed -E 's/\^\[\[(.;.)?.m//g';
    done;
}

stdout_raw () {
    # Convert invisible color codes to raw output
    while read -r data; do
        /bin/cat -v <<< "$data";
    done;
}

stdout_stripe () {
    # Stripe input background color per line
    # args: invert
    local op='!=';
    if [ "$1" = "invert" ]; then op='=='; fi;
    stdout_apply "python3 -c \"
import sys
import re
for i, line in enumerate(sys.argv[1].split('\n')):
    if i % 2 $op 0:
        line = re.sub(r'\[0;', '[40;', line)
        line = re.sub(r'\[0m', '[40m', line)
        line = '\x1b[40;40m' + line + '\x1b[0;0m'
    print(line)
\"";
}

stdout_sub () {
    # Substitute given pattern with given value
    # args: pattern, replacement
    stdout_apply "python3 -c '
import re
import sys
print(re.sub(*sys.argv[1:4], flags=re.I))
' $1 $2";
}
