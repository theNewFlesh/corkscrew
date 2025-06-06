# requires: docker, parallel, vscode

source $ZSH_SCRIPTS/stdout_tools.sh

app_list () {
    # List all datalus style repos in a given directory
    # args: directory=$PROJECTS_DIR
    local cwd=`pwd`;
    local projects=$PROJECTS_DIR;
    if [ "$1" ]; then projects=$1; fi;
    cd $projects;
    repo_list $projects \
        | sed 's/.*\///' \
        | parallel "find {} -type f -maxdepth 3 | grep 'bin/{}$'" \
        | sed 's/\/.*//' \
        | sort \
        | uniq;
    cd $cwd;
}

app_state () {
    # Shows the state of all datalus style repos in a given directory
    # args: directory=$PROJECTS_DIR
    local projects=$PROJECTS_DIR;
    if [ "$1" ]; then projects=$1; fi;

    echo "${CYAN1}APP,VERSION,IMAGE,CONTAINER,PORTS${CLEAR}" \
        | awk -F ',' '{printf("%-32s%-12s%-11s%-12s%s\n", $1, $2, $3, $4, $5)}';

    app_list $projects \
        | parallel "cd $projects/{}; bin/{} state 2>&1 | grep -E app" \
        | sort \
        | sed 's/ -/\t/g' \
        | awk '{printf("%s %-34s %9s %-19s %9s %-20s %11s %-21s %7s %-29s %20s %-29s %20s %-29s %20s\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)}' \
        | sed -E 's/ +$//g' \
        | sed -E 's/[a-z]+: //g' \
        | stdout_buffer \
        | stdout_stripe invert;
}

app_ports () {
    # List port prefixes of all datalus style repos in a given directory
    local active=`
        netstat \
        | awk '{print $4}' \
        | grep -E 'localhost:....$' \
        | sed -E 's/.*:(..)../\1/' \
        | sort \
        | uniq \
        | tr '\n' '|' \
        | sed 's/|$//'
    `;
    app_state \
        | stdout_decolor \
        | grep -v CONTAINER \
        | awk '{print $1, $5}' \
        | grep '\-\->' \
        | sed 's/-->.*//' \
        | sed -E 's/ (..).*/ \1/' \
        | awk '{print $2, $1}' \
        | sort \
        | sed -E "s/($active)/;\1/" \
        | sed -E $'s/;(.*)/\e[92m\\1\e[0m/';
}

app_ps () {
    # Run docker top against a given datalus repo
    # args: repo_name
    echo "${GREEN1}PID                 PPID                COMMAND${CLEAR}";
    docker top $1 -o pid,ppid,cmd 2>&1 | grep -vE 'PPID|vscode|Error';
}

app_top () {
    # Run docker top against all datalus repos in a given directory
    # args: directory=$PROJECTS_DIR
    local projects=$PROJECTS_DIR;
    if [ "$1" ]; then projects=$1; fi;
    app_list $projects \
        | parallel "cd $projects; find {} -type f | grep 'bin/{}$'" \
        | sed 's/\/.*//' \
        | sort \
        | parallel " \
            echo '$CYAN1{}$CLEAR'; \
            echo '${GREEN1}PID                 PPID                COMMAND${CLEAR}'; \
            docker top {} -o pid,ppid,cmd 2>&1 | grep -vE 'PPID|vscode|Error'; \
            echo" \
        | grep '^\d' --color=never -B 2 \
        | sed 's/^--$//g';
}

app_xtools () {
    # List all x_tools commands within a given repo
    # args: repo directory
    local repo_dir='.';
    if [ "$1" ]; then repo_dir=$1; fi;
    cat "$repo_dir/docker/scripts/x_tools.sh" \
        | grep -E '^[a-z_].* \(\) \{' -A 2 \
        | grep -E '^[a-z_].* \(\)|^ +#' \
        | sed -E 's/(.*) \(\) \{/@\1/' \
        | tr '\n' ' ' \
        | tr '@' '\n' \
        | sed -E 's/^ +//' \
        | grep -vE '^$' \
        | awk -F '#' '{printf("%-40s%-90s%s\n", $1, $2, $3)}' \
        | grep -vE '^_' \
        | sort;
}
