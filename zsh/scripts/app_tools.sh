# requires: docker, parallel, vscode

app_list () {
    # List all datalus style repos in a given directory
    # args: directory='~/Documents/projects'
    local cwd=`pwd`;
    export projects=~/Documents/projects;
    if [ "$1" ]; then export projects=$1; fi;
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
    # args: directory='~/Documents/projects'
    export projects=~/Documents/projects;
    if [ "$1" ]; then export projects=$1; fi;
    app_list $projects \
        | parallel "cd $projects/{}; bin/{} state 2>&1 | grep -E app" \
        | sort \
        | sed 's/ -/\t/g' \
        | awk '{printf("%s %-34s %9s %-19s %9s %-20s %11s %-20s %7s %-29s %20s %-29s %20s %-29s %20s\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)}' \
        | sed -E 's/ +$//g';
}

app_ports () {
    # List port prefixes of all datalus style repos in a given directory
    app_state \
        | awk '{print $2, $10}' \
        | grep '\-\->' \
        | sed 's/-->.*//' \
        | sed -E 's/(..)(00|80)/\1/' \
        | awk '{print $2, $1}' \
        | sort;
}

app_ps () {
    # Run docker top against a given datalus repo
    # args: repo_name
    echo "${GREEN1}PID                 PPID                COMMAND${CLEAR}";
    docker top $1 -o pid,ppid,cmd 2>&1 | grep -vE 'PPID|vscode|Error';
}

app_top () {
    # Run docker top against all datalus repos in a given directory
    # args: directory='~/Documents/projects'
    export projects=~/Documents/projects;
    if [ "$1" ]; then export projects=$1; fi;
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
