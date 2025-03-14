# requires: docker, parallel
source $ZSH_SCRIPTS/colors.sh

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
    local cmd=` \
        find $ZSH/custom/scripts -type f \
            | grep tools \
            | parallel "cat {} \
                | grep -E '^[a-z_].* \(\) \{' -A 2 \\
                | grep -E '^[a-z_].* \(\)|^ +#' \
                | sed -E 's/(.*) \(\) \{/@\1/'" \
            | tr '\n' ' ' \
            | tr '@' '\n' \
            | sed -E 's/^ +//' \
            | grep -vE '^$' \
    `;
    local public=`echo "$cmd" | grep -vE '^_' | sort`;
    local private=`echo "$cmd" | grep -E '^_' | sort`;
    echo "$private\n$public" \
        | awk \
            -F '#' \
            -v cyan="$CYAN2" -v clear="$CLEAR" \
            '{printf cyan "%-40s" clear "%-90s" "%s\n", $1, $2, $3}' \
        | sed -E "s/^'|'$//g";
}

ls_displays () {
    # List all displays
    w -hs | awk '{print $3}' | sort -u;
}

ls_docker_containers () {
    # List all docker containers in a nicely formatted table
    local header=`
        echo "${GREEN2}NAME|STATE|STATUS|CREATED|ID${CLEAR}" \
        | awk -F '|' '{printf("%-35s%-12s%-30s%-35s%s\n", $1, $2, $3, $4, $5)}'
    `;
    local body=`docker ps \
        --all \
        --format '{{.Names}}|{{.State}}|{{.Status}}|{{.CreatedAt}}|{{.ID}}' \
        | awk -F '|' '{printf("%-28s%-12s%-30s%-35s%s\n", $1, $2, $3, $4, $5)}' \
        | sort
    `;
    echo "$header\n$body" | stdout_buffer | stdout_stripe;
}

ls_docker_images () {
    # List all docker images in a nicely formatted table
    local header=`
        echo "${GREEN2}REPOSITORY|TAG|SIZE|CREATED|ID${CLEAR}" \
        | awk -F '|' '{printf("%-47s%-20s%-10s%-35s%s\n", $1, $2, $3, $4, $5)}'
    `;
    local body=`docker images \
        --format '{{.Repository}}|{{.Tag}}|{{.Size}}|{{.CreatedAt}}|{{.ID}}' \
        | sort \
        | grep -v none \
        | sed -E 's/(vsc-[^;]+)-[^;]+-uid/\1/' \
        | awk -F '|' '{printf("%-40s%-20s%-10s%-35s%s\n", $1, $2, $3, $4, $5)}'
    `;
    echo "$header\n$body" | stdout_buffer | stdout_stripe;
}

ls_docker () {
    # List all docker entities in a nicely formatted table
    echo "${CYAN2}CONTAINERS${CLEAR}";
    ls_docker_containers;
    echo "\n${CYAN2}IMAGES${CLEAR}";
    ls_docker_images;
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
