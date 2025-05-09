# requires: ffmpeg, jq, lunchbox, parallel, python3, tabulate

source $ZSH_SCRIPTS/colors.sh
source $ZSH_SCRIPTS/variables.sh
source $ZSH_SCRIPTS/ls_tools.sh
source $ZSH_SCRIPTS/stdout_tools.sh

chmod_it () {
    # Chmod given item
    # args: user, group, other, item
    sudo chmod u=$1,g=$2,o=$3 $4;
}

colorscheme () {
    # Display color scheme information
    echo "${CYAN2}NAME       HEX        TERMINAL    ${CLEAR}
${DARK1}dark1      #040404                ${CLEAR}
${DARK2}dark2      #141414                ${CLEAR}
bg         #242424
${GREY1}grey1      #343434    \\\033[0;90m$ ${CLEAR}
${GREY2}grey2      #444444    \\\033[0;37m$ ${CLEAR}
${LIGHT1}light1     #A4A4A4    \\\033[0;97m$ ${CLEAR}
${LIGHT2}light2     #F4F4F4    \\\033[0;97m$ ${CLEAR}
${RED1}red1       #F77E70    \\\033[0;31m$ ${CLEAR}
${RED2}red2       #DE958E    \\\033[0;91m$ ${CLEAR}
${ORANGE1}orange1    #EB9E58                ${CLEAR}
${ORANGE2}orange2    #EBB483                ${CLEAR}
${YELLOW1}yellow1    #E8EA7E    \\\033[0;33m$ ${CLEAR}
${YELLOW2}yellow2    #E9EABE    \\\033[0;93m$ ${CLEAR}
${GREEN1}green1     #8BD155    \\\033[0;32m$ ${CLEAR}
${GREEN2}green2     #A0D17B    \\\033[0;92m$ ${CLEAR}
${CYAN1}cyan1      #7EC4CF    \\\033[0;36m$ ${CLEAR}
${CYAN2}cyan2      #B6ECF3    \\\033[0;96m$ ${CLEAR}
${BLUE1}blue1      #5F95DE    \\\033[0;34m$ ${CLEAR}
${BLUE2}blue2      #93B6E6    \\\033[0;94m$ ${CLEAR}
${PURPLE1}purple1    #C98FDE    \\\033[0;35m$ ${CLEAR}
${PURPLE2}purple2    #AC92DE    \\\033[0;95m$ ${CLEAR}
clear                 \\\033[0m
";
}

count () {
    # Count all files in given directory
    # args: directory=`pwd`
    local input=`pwd`;
    if [[ $1 ]]; then
        local input=$1;
    fi;
    ls $input | grep -v -E '^.$|^..$' | wc | awk '{print $1}';
}

easy_mount () {
    # Mkdir directory and mount device to it
    # args: device, directory
    sudo mkdir -p $2;
    sudo mount $1 $2;
}

easy_unmount () {
    # Unmount given volume and delete its directory
    # args: directory
    sudo umount $1;
    sudo rm -rf $1;
}

flat_json () {
    # Converts json input into flattened json
    # args: JSON text
    local json="$1";
    if [ "$json" = "" ]; then
        json=`cat /dev/stdin`
    fi;
    echo "$json" \
    | jq -r 'paths(scalars) as $p | "\($p | join(".")): \(getpath($p))"' \
    | yq --output-format json \
    | jq -c;
}

_generate_password () {
    # Generate password
    python3 -c "
import string
import random

alpha = string.ascii_lowercase
nums = string.digits
special = '~!@#$%^&*_+-=[];,?'
chars = alpha + nums
wa = len(alpha)
wn = len(nums)
weights = [wn / wa] * wa
weights += [wa / wn] * wn
weights = [x / sum(weights) for x in weights]
password = random.choices(chars, weights=weights, k=18)
password += random.choice(string.ascii_uppercase)
password += random.choice(special)
password = ''.join(password)
print(password)
";
}

generate_password () {
    # Generate password and append it to /tmp/password.txt
    local password=`source $ZSH_SCRIPTS/misc_tools.sh; _generate_password`;
    touch /tmp/password.txt;
    echo "$password" >> /tmp/password.txt;
    echo "$password";
}

get_noncomments () {
    # Cat given file removing comments
    # args: file
    cat $1 | grep -v -E '^\w*#|^\w*//|^$';
}

git_merge_prod () {
    # Merge prod into master for a given repo
    local branch='master';
    local found=` \
        git --no-pager branch --all --no-color \
        | sed -E 's/\* /  /g' \
        | grep -v remotes \
        | grep main;
    `;
    if [ "$found" != "" ]; then
        branch='main';
    fi;
    git checkout $branch;
    git pull;
    git checkout prod;
    git pull;
    git checkout $branch;
    git merge prod --strategy ours --no-edit;
    git push;
}

keygen () {
    # Generate ed25519 public private key pair
    # args: name
    ssh-keygen -t ed25519 -f $1 -C $1 -P '';
    chmod 400 $1;
    mv $1 $1.pem;
    chmod 400 $1.pub;
}

kill_proc () {
    # Kill processes that match given grep pattern
    # args: pattern
    ls_proc $1 --pid | xargs sudo kill -9;
}

lookup () {
    # Searches all custom commands and aliases with given regex
    # args: regex
    local _alias=`ls_alias | awk '{printf("%-40s alias\n", $1)}'`;
    (ls_cmd && echo "$_alias") \
    | stdout_decolor \
    | grep -iE "$1" \
    | sed -E "s/'//g" \
    | stdout_buffer \
    | stdout_stripe;
}

notebook_cells () {
    # Echo notebook cells of given ipynb file
    # args: ipynb file
    cat $1 \
    | jq '.cells[].source' \
    | sed -E 's/^ *"|",$|\\n//g' \
    | sed -E 's/^\[\]|^\[//' \
    | sed -E "s/^\]/\\$CYAN2$SPACER\\$CLEAR/" \
    | parallel 'echo {}';
}

progress () {
    # Eval given command every 1 second and echo to output
    # args: command, --no-clear
    if [[ "$2" != '--no-clear' ]]; then clear; fi;
    export TEMP=`eval $1`;
    while [ true ]; do
    echo $TEMP;
    sleep 1;
    export TEMP=`eval $1`;
        if [[ "$2" != '--no-clear' ]]; then clear; fi;
    done;
}

rm_cache () {
    # Remove cache files and directories from given directories
    # args: directory
    find $1 \
    | grep -E '__pycache__|\.pyc$|\.mypy_cache|\.pytest_cache' \
    | parallel 'rm -rf {}';
}

set_logic () {
    # Apply set logic to a and b
    # args: a, b, separator, method
    local sep="$3";
    if [ "$sep" = "" ]; then
        sep='newline'
    fi;

    local method="$4";
    if [ "$method" = "" ]; then
        method='symmetric_difference'
    fi;

    local cmd=$(cat <<EOF
import sys
a, b, sep, func = sys.argv[1:5]
if sep == 'newline':
    sep = '\n'
a = set(a.split(sep))
b = set(b.split(sep))
diff = getattr(a, func)(b)
diff = '\n'.join(sorted(list(diff)))
print(diff)
EOF
)
    python3 -c "$cmd" "$1" "$2" "$sep" "$method" | grep -vE '^$';
}

_slack_it () {
    # Slack message to given channel
    # args: url, channel, message
    local message="$3";
    if [ "$message" = "" ]; then
        message=`cat /dev/stdin`
    fi;
    lb slack "$1" "$2" "$message";
}

slack_it () {
    # Slack message to given channel
    # args: channel, message
    _slack_it $SLACK_URL "$1" "$2";
}

ssh_add_all () {
    # Ssh-add all files in ~/.ssh
    cd ~/.ssh;
    ls | grep -vE '.DS_Store|config|\.pub$|^old$' \
        | parallel "echo -n '{} '; cat {} | head -n 1" \
    | grep -E '\-+BEGIN.*PRIVATE KEY-+' \
    | awk '{print $1}' \
    | parallel 'ssh-add {}';
}

ssh_exec () {
    # SSH to a machine and run a given command
    # args: machine, command 
    ssh $1 "/bin/zsh -c 'source ~/.zshrc; $2'";
}

tabulate () {
    # Format YAML of stdin into table
    # args: headers (comma separated), table-format=fancy_grid, stdin
    local format='fancy_grid';
    if [ "$2" ]; then
        local format="$2";
    fi;
    python3.11 -c "
import sys
import yaml
import tabulate as tb
stdin = yaml.safe_load(sys.argv[1])
stdout = tb.tabulate(stdin, headers='$1'.split(','), tablefmt='$format')
print(stdout)
" "`cat /dev/stdin`" && \
}

to_mp4 () {
    # Convert given file to mp4
    # args: video file
    local SHAPE=`ffmpeg -i $1 2>&1 \
        | grep Stream \
        | grep Video \
        | sed -E 's/.* ([0-9]+x[0-9]+).*/\1/'`; \
    local SIZE="$3"000000; \
    ffmpeg \
        -i $1 \
        -s $SHAPE \
        -vcodec libx264 \
        -preset veryslow \
        -profile:v high444 \
        -acodec aac \
        -r 24 \
        -movflags +faststart $2 \
        -hide_banner;
}
