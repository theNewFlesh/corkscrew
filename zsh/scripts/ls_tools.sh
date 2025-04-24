# requires: cruft, docker, nvidia-smi, parallel

source $ZSH_SCRIPTS/variables.sh
source $ZSH_SCRIPTS/colors.sh
source $ZSH_SCRIPTS/app_tools.sh
source $ZSH_SCRIPTS/f_tools.sh
source $ZSH_SCRIPTS/repo_tools.sh
source $ZSH_SCRIPTS/stdout_tools.sh

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

ls_cruft () {
    # Display table of all local repos and their cruft git hash
    cd $PROJECTS_DIR;
    echo "${CYAN2}REPO CRUFT-HASH DATE COMMIT${CLEAR}" \
        | awk '{printf("%-49s%-42s%-35s%s\n", $1, $2, $3, $4)}';
    app_list \
        | f_find cruft.json \
        | sed -E 's/\/.*//' \
        | f_line "cat {}/.cruft.json | grep commit | sed -E 's/.* \"|\",//g'" \
        | parallel \
            "echo '%{}' \
            | sed -E 's/(.*) (.*)/echo \1; \
            cd ~\/Documents\/projects\/cookiecutter-datalus; \
            git log --date iso \| grep \2 -A 5 \| grep -v Author/'" \
        | sed 's/\\//g' \
        | parallel \
        | tr '\n' ' ' \
        | tr '%' '\n' \
        | grep -vE '^$' \
        | sed 's/ commit/%/' \
        | awk -F '%' '{printf("%-40s %s\n", $1, $2)}' \
        | sed 's/ Date: //' \
        | sed -E 's/  +/;/g' \
        | awk -F ';' '{printf("%-42s%-42s%-35s%s\n", $1, $2, $3, $4)}' \
        | stdout_buffer \
        | stdout_stripe invert;
}

ls_displays () {
    # List all displays
    w -hs | awk '{print $3}' | sort -u;
}

ls_docker_containers () {
    # List all docker containers in a nicely formatted table
    echo "${CYAN2}NAME|STATE|STATUS|CREATED|ID${CLEAR}" \
        | awk -F '|' '{printf("%-35s%-12s%-30s%-35s%s\n", $1, $2, $3, $4, $5)}'
    docker ps \
        --all \
        --format '{{.Names}}|{{.State}}|{{.Status}}|{{.CreatedAt}}|{{.ID}}' \
        | awk -F '|' '{printf("%-28s%-12s%-30s%-35s%s\n", $1, $2, $3, $4, $5)}' \
        | sed -E $'s/running/\e[92mrunning\e[0m/' \
        | sed -E $'s/exited/\e[31mexited\e[0m/' \
        | sort;
}

ls_docker_images () {
    # List all docker images in a nicely formatted table
    local header=`
        echo "${CYAN2}REPOSITORY|TAG|SIZE|CREATED|ID${CLEAR}" \
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
    echo "${PURPLE2}CONTAINERS${CLEAR}";
    ls_docker_containers;
    echo "\n${YELLOW2}IMAGES${CLEAR}";
    ls_docker_images;
}

ls_fileperms () {
    # List file permissions
    # args: directory=`pwd`
    export cwd=`pwd`;
    if [ "$1" ]; then export cwd=$1; fi;
    echo "${CYAN2}PERMISSION  OWNER  GROUP${CLEAR}";
    ls -lRA $cwd \
        | grep -E '^-' \
        | awk '{printf("%s  %s   %s\n", $1, $3, $4)}' \
        | sort \
        | uniq \
        | stdout_buffer \
        | stdout_stripe invert;
}

ls_nvidia () {
    # List nvidia processes
    echo "${CYAN2}GPU USAGE   PID       PROCESS${CLEAR}";
    nvidia-smi \
        | grep 'GPU Memory' -A 1000 \
        | grep '|=' -A 1000 \
        | grep '| ' \
        | sed -E 's/^.* ([0-9]+) .* ([0-9]+MiB).*/\1 \2/' \
        | awk ' \
            {printf("echo -n \"%s %s\"; \
            ps aux \
            | grep %s \
            | grep -v grep \
            | sed -E \"s/^.* [0-9]+:[0-9]+ / /\"\n", $1, $2, $1)}' \
        | parallel \
        | awk '{print $1, $2, $3}' \
        | grep MiB \
        | awk '{printf("%9s   %-10s%s\n", $2, $1, $3)}' \
        | sed -E 's/^  /00/' \
        | sort \
        | sed -E 's/^00/;;/' \
        | stdout_buffer \
        | stdout_stripe invert \
        | sed 's/;;/  /';
}

ls_proc () {
    # List all processes that math given grep pattern
    # args: pattern, --pid (shows process ids)
    if [[ $2 == --pid ]]; then
        ps aux | grep -i $1 | grep -v grep | awk '{print $2}';
        return;
    fi;
    ps aux | grep -i $1 | grep -v grep | awk '{print $11}';
    return;
}

_ls_github_repos () {
    # List all personal GitHub source repos
    curl -s https://github.com/$GITHUB_USER\?tab\=repositories\&q\=\&type\=source\&language\=\&sort\= \
        | grep 'name codeRepository' -A 1 \
        | grep -v 'name codeRepository' \
        | sort \
        | uniq \
        | sed -E 's/<.*//' \
        | sed -E 's/ +//' \
        | grep -v '\--';
}

ls_github_repos () {
    # List all personal GitHub source repos
    local all_repos=`_ls_github_repos | tr '\n' ',' | sed 's/,$//'`;
    local local_repos=`repo_list | tr '\n' ',' | sed 's/,$//'`;
    local remote_repos=`set_logic "$all_repos" "$local_repos" ',' difference`

    echo "${CYAN2}LOCAL REPOS${CLEAR}";
    set_logic "$local_repos" "$remote_repos" ',' difference \
        | stdout_buffer \
        | stdout_stripe invert;

    echo "\n${CYAN2}REMOTE REPOS${CLEAR}";
    echo "$remote_repos" | stdout_buffer | stdout_stripe invert;
}
