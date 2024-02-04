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
    # Cleanup given input, removing color codes
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

stdout_decolor () {
    # Cleanup given input, removing color codes
    while read -r data; do
        /bin/cat -v <<< "$data" | sed -E 's/\^\[\[(.;.)?.m//g';
    done;
}

stdout_raw () {
    # Returns given output with colot codes
    while read -r data; do
        /bin/cat -v <<< "$data";
    done;
}

stdout_stripe () {
    # Stripe input background color per line
    stdout_apply "python3 -c \"
import sys
import re
for i, line in enumerate(sys.argv[1].split('\n')):
    if i % 2 != 0:
        line = re.sub('\[0;', '[40;', line)
        line = re.sub('\[0m', '[40m', line)
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
