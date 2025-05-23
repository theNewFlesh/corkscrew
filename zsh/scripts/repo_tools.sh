# requires: parallel

source $ZSH_SCRIPTS/variables.sh
source $ZSH_SCRIPTS/stdout_tools.sh

_repo_list_long () {
    # List all git repo fullpaths under a given directory
    # args: directory=$PROJECTS_DIR
    local projects="$PROJECTS_DIR";
    if [ "$1" ]; then local projects=$1; fi;
    find $projects -maxdepth 2 \
        | grep -E '\.git$' \
        | sed -E 's/\/\.git$//' \
        | sort;
}

repo_list () {
    # List all git repos under a given directory
    # args: directory=$PROJECTS_DIR
    _repo_list_long $1 | sed -E 's/.*\///' | sort;
}

_repo_status_long () {
    # List git status of all git repos (fullpaths) under given directory
    # args: directory=$PROJECTS_DIR
    _repo_list_long $1 \
        | parallel "echo '{}XXXXX'; cd {}; git status -s; echo ' EOF'" \
        | tr '\n' ' ' \
        | tr EOF '\n' \
        | parallel "echo {} \
        | sed -E 's/^ +//g'" \
        | grep -vE '^$' \
        | sort \
        | parallel "
            echo {} \
            | sed -E 's/XXXXX  $/ \\${GREEN1}clean\\${CLEAR}/' \
            | sed -E 's/XXXXX...+/ \\${RED1}dirty\\${CLEAR}/'
        " \
        | awk '{print $2, $1}' \
        | sort \
        | parallel 'echo -e {}';
}

repo_status () {
    # List git status of all git repos under given directory
    # args: directory=$PROJECTS_DIR
    _repo_status_long $1 | sed 's/\/.*\///';
}

repo_dirty_details () {
    # List only dirty git repos under a given directory
    # args: directory=$PROJECTS_DIR
    _repo_status_long $1 | grep dirty | awk '{print $2}' \
        | f "cd {}; git status --porcelain \
        | sed 's/.M /modified /' \
        | sed 's/.A /added /' \
        | sed 's/.D /deleted /' \
        | sed 's/.R /renamed /' \
        | sed 's/.C /copied /' \
        | sed 's/.U /updated /' \
        | sed 's/?? /untracked /' \
        | awk '{printf(\"%-15s %s\n\", \$1, \$2)}'
    "
}

_repo_branches () {
    # List git branches of all git repos under given directory
    # args: directory
    local cwd=`pwd`;

    source $ZSH_SCRIPTS/misc_tools.sh;

    local target=$cwd;
    if [ "$1" ]; then target=$1; fi;
    local repos=`_repo_list_long $target`;
    fmt () { awk -F ';' '{printf("%-40s %-5s %s\n", $1, $2, $3)}' };

    for repo in $repos; do
        cd $repo;

        local branches=`\
            git --no-pager branch --all --format '%(refname)' 2>&1 \
            | grep -vE 'HEAD|dependabot|warning: '\
        `;
        local lb=`echo "$branches" \
            | grep -v '/remotes/' | sed -E 's/.*heads\///' | tr '\n' ','`;
        local rb=`echo "$branches" \
            | grep '/remotes/' | sed -E 's/.*origin\///' | tr '\n' ','`;

        set_logic "$lb" "$rb" ',' difference \
            | parallel "echo '{};local;'" | fmt;
        set_logic "$rb" "$lb" ',' difference \
            | parallel "echo '{};;remote'" | fmt;
        set_logic "$lb" "$rb" ',' intersection \
            | parallel "echo '{};local;remote'" | fmt;
    done;

    cd $cwd;
}

repo_branches () {
    # List git branches of all git repos under given directory
    # args: regex
    local regex='.*';
    if [ "$1" ]; then regex=$1; fi;
    _repo_list_long | parallel "\
        source $ZSH_SCRIPTS/repo_tools.sh; \
        echo -n '${CYAN}'; echo -n {} | sed 's/.*\///'; echo '${CLEAR}'; \
        _repo_branches {} | grep -E \"$regex\"; \
        echo \
    " | parallel 'echo {}';
}

repo_pull () {
    # Git pull all clean repos under given directory
    # args: directory=$PROJECTS_DIR
    local pwd=`pwd`; \
    _repo_status_long $1 \
        | grep clean \
        | awk '{print $2}' \
        | parallel "
            echo -n '${CYAN}'; echo -n {} | sed 's/.*\///'; echo '${CLEAR}' && \
            cd {} && \
            git pull && \
            echo $SPACER
        "; \
    cd $pwd; \
}

repo_prune () {
    # Git remote prune origin all repos under given directory
    # args: directory=$PROJECTS_DIR
    local pwd=`pwd`; \
    _repo_status_long $1 \
        | grep clean \
        | awk '{print $2}' \
        | parallel "
            echo -n '${CYAN}'; echo -n {} | sed 's/.*\///'; echo '${CLEAR}' && \
            cd {} && \
            git remote prune origin && \
            echo $SPACER
        "; \
    cd $pwd; \
}

_repo_versions () {
    # List all git version tags of all git repos (fullpath) under given directory
    # args: directory=$PROJECTS_DIR
    local pwd=`pwd`;
    cd $1;
    git --no-pager log \
        --format='%H | %s | %d' \
        --grep '[0-9]\+\.[0-9]\+\.[0-9]\+' \
    | awk -F '|' '{printf("%-45s %-35s %-35s\n", $1, $2, $3)}';
    cd $pwd;
}

repo_versions () {
    # List all git version tags of all git repos under given directory
    # args: directory=$PROJECTS_DIR
    if [ "$1" ]; then
        _repo_versions $1;
    else
        local home=`echo ~`;
        local projects="$home/Documents/projects";
        repo_list | f "\
            source $ZSH_SCRIPTS/repo_tools.sh; \
            _repo_versions $projects/{} \
        "
    fi;
}

repo_version () {
    # Intelligently find version from given repo
    # args: directory=cwd
    local cwd='.';
    if [ "$1" ]; then local cwd=$1; fi;

    # look for version file
    local filepath=`find $cwd \
            -maxdepth 3 \
            -type f \
            ! -path "**/node_modules/*" \
            ! -path "**/.git/*" \
            ! -path "**/labextension/*" \
        | grep -E 'config/pyproject.toml|version.txt|galaxy.yml' \
        | head -n 1 \
    `;

    # look at Chart.yaml files if no version file found
    if [ "$filepath" = '' ]; then
        local filepath=`find $cwd \
                -maxdepth 2 \
                -type f \
                ! -path "**/node_modules/*" \
                ! -path "**/.git/*" \
                ! -path "**/labextension/*" \
            | grep -E 'Chart.yaml' \
            | head -n 1 \
        `;
    fi;

    # look at package.json files if no version file found
    if [ "$filepath" = '' ]; then
        local filepath=`find $cwd \
                -maxdepth 2 \
                -type f \
                ! -path "**/node_modules/*" \
                ! -path "**/.git/*" \
                ! -path "**/labextension/*" \
            | grep -E '\./package.json' \
            | head -n 1 \
        `;
    fi;

    local filename=`echo $filepath | sed -E 's/.*\///'`;
    local version="none";

    # get version
    if [ "$filename" = 'pyproject.toml' ]; then
        local version=`cat $filepath 2> /dev/null \
            | grep -E '^version *=' \
            | awk '{print $3}' \
            | sed 's/"//g'`;

    elif [ "$filename" = 'version.txt' ]; then
        local version=`cat $filepath 2> /dev/null`;

    elif [ "$filename" = 'galaxy.yml' ]; then
        local version=`cat $filepath 2> /dev/null \
            | grep -E '^version: ' \
            | awk '{print $2}' \
        `;

    elif [ "$filename" = 'Chart.yaml' ]; then
        local version=`cat $filepath 2> /dev/null \
            | grep -E '^version: ' \
            | awk '{print $2}' \
        `;

    elif [ "$filename" = 'package.json' ]; then
        local version=`cat $filepath 2> /dev/null \
            | grep -E '"version": ' \
            | sed -E 's/("|,)//g' \
            | awk '{print $2}' \
        `;
    fi;

    # assign version to none if nothing is found
    if [ "$version" = '' ]; then
        local version="none";
    fi;
    echo "$version";
}

_repo_state () {
    # List git statu of all git repos (fullpath) under given directory in simple table
    # args: directory=$PROJECTS_DIR
    local pwd=`pwd`;
    cd $1;
    local REPO=`echo $1 | sed -E 's/.*\///'`;

    # version
    local VERSION=`source $ZSH_SCRIPTS/repo_tools.sh; repo_version .`;
    if [ "$VERSION" = 'none' ]; then
        VERSION="${PURPLE1}$VERSION${CLEAR}";
    else
        VERSION="${YELLOW1}$VERSION${CLEAR}";
    fi;

    # branch
    local BRANCH=`git branch --show-current`;
    local master=`echo $BRANCH | grep -E '^(master|main)$'`;
    if [ "$master" != '' ]; then
        BRANCH="${BLUE1}$BRANCH${CLEAR}";
    else
        BRANCH="${YELLOW1}$BRANCH${CLEAR}";
    fi;

    local COMMIT=`git --no-pager log -n 1 --abbrev-commit | head -n 1 | sed -E 's/^commit +//'`;
    local MESSAGE=`git --no-pager log -n 1 | tail -n 1 | sed -E 's/^ +//' | cut -c -50`;

    # state
    local STATUS=`git status -s`;
    local STATE="${GREEN1}clean${CLEAR}";
    if [ "$STATUS" ]; then
        local STATE="${RED1}dirty${CLEAR}";
    fi;

    echo "repo: ${GREY2}$REPO${CLEAR}\
|version: ${VERSION}\
|state: ${STATE}\
|branch: ${BRANCH}\
|commit: ${GREY2}$COMMIT${CLEAR}\
|message: ${GREY2}$MESSAGE${CLEAR}";
}

repo_state () {
    # List git statu of all git repos under given directory in simple table
    # args: directory=$PROJECTS_DIR
    echo "${CYAN1}REPO,VERSION,STATE,BRANCH,COMMIT,MESSAGE${CLEAR}" \
    | awk -F ',' '{printf("%-41s%-10s%-9s%-32s%-11s%s\n", $1, $2, $3, $4, $5, $6)}';

    _repo_list_long $1 | parallel \
        "source $ZSH_SCRIPTS/repo_tools.sh; _repo_state {}" \
    | sort \
    | awk -F '|' '{printf("%-50s %-29s %-26s %-50s %-29s %-50s\n", $1, $2, $3, $4, $5, $6)}' \
    | sed -E 's/[a-z]+: //g' \
    | stdout_buffer \
    | stdout_stripe invert;
}
