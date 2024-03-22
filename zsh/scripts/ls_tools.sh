ls_alias () {
    # List all custom aliases
    cat $ZSH/custom/scripts/aliases.sh \
        | grep -E '^alias' \
        | sed 's/=.*//' \
        | sed 's/alias //' \
        | sort;
}

ls_cmd () {
    # List all custom commands
    find $ZSH/custom/scripts -type f \
        | grep tools \
        | parallel "cat {} \
            | grep -E '\(\) \{' -A 2 \
            | grep -E '\(\)|#' \
            | sed -E 's/(.*) \(\) \{/@\1/'" \
        | tr '\n' ' ' \
        | tr '@' '\n' \
        | sed -E 's/^ +//' \
        | grep -vE '^$' \
        | awk \
            -F '#' \
            -v cyan="$CYAN2" -v clear="$CLEAR" \
            '{printf cyan "%-40s" clear "%-90s" "%s\n", $1, $2, $3}' \
        | sed -E "s/^'|'$//g" \
        | sort;
}

ls_displays () {
    # List all displays
    w -hs | awk '{print $3}' | sort -u;
}

ls_fileperms () {
    # List file permissions
    # args: directory=`pwd`
    export cwd=`pwd`;
    if [ "$1" ]; then export cwd=$1; fi;
    ls -lRA $cwd | grep -E '^-' | awk '{print $1, $3, $4}' | sort | uniq;
}

ls_ip () {
    # List all ips under ip addr
    ip addr \
        | grep -E '\d+\.\d+\.\d+\.\d+' \
        | awk '{print $2}' \
        | sed 's/\/.*//' \
        | sort \
        | uniq;
}

ls_net () {
    # Ping all arp entries
    arp -a \
        | sed -E 's/ at |\? |\(|\).*/ /g' \
        | sed -E 's/ +/>/g' \
        | awk -F '>' '{print $2, $1}' \
        | parallel " \
            echo -n '{}>' | sed -E 's/ +/>/g'; \
            ping -c 2 `echo {} \
            | awk '{print $1}'` 2>&1 \
            | grep 'packet loss' \
            | sed -E 's/.*([0-9.]+%)/\\1/g' \
            | sed -E 's/ +/-/g' \
        " \
        | awk -F '>' '{printf("%-20s %-20s %s\n", $1, $3, $2)}' \
        | sort;
}

ls_proc () {
    # List all processes that math given grep pattern
    # --pid will show process ids
    # args: pattern, --pid
    if [[ $2 == --pid ]]; then
        ps aux | grep -i $1 | grep -v grep | awk '{print $2}';
        return;
    fi;
    ps aux | grep -i $1 | grep -v grep | awk '{print $11}';
    return;
}
