chmod_it () {
    # Chmod given item
    # args: user, group, other, item
    sudo chmod u=$1,g=$2,o=$3 $4;
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

get_noncomments () {
    # Cat given file removing comments
    # args: file
    cat $1 | grep -v -E '^\w*#|^\w*//|^$';
}

kill_proc () {
    # Kill processes that match given grep pattern
    # args: pattern 
    ls_proc $1 --pid | xargs sudo kill -9;
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

to_mp4 () { \
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

keygen () {
    # Generate ed25519 public private key pair
    # args: name
    ssh-keygen -t ed25519 -f $1 -C $1 -P '';
    chmod 400 $1;
    mv $1 $1.pem;
    chmod 400 $1.pub;
}

rm_cache () {
    # Remove cache files and directories from given directories
    # args: directory
    find $1 \
    | grep -E '__pycache__|\.pyc$|\.mypy_cache|\.pytest_cache' \
    | parallel 'rm -rf {}';
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
