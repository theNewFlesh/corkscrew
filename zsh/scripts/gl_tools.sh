# requires: glab, jq, parallel

source $ZSH_SCRIPTS/variables.sh
source $ZSH_SCRIPTS/stdout_tools.sh

gl_repos () {
    # List all GitLab repos
    glab repo list -P 1000 \
    | awk '{print $1}' \
    | sed 's/.*\///' \
    | sort \
    | grep -vE 'Showing|^$';
}

gl_local_repos () {
    # List all local GitLab repos
    local disk=`repo_list | tr '\n' ','`;
    local gitlab=`gl_repos | tr '\n' ','`;
    set_logic "$disk" "$gitlab" , intersection | sort;
}

gl_mrs () {
    # List all open GitLab merge requests for the current repo
    echo "${CYAN2}TITLE|SOURCE|TARGET|AUTHOR|REVIEWER|STATUS|DETAIL${CLEAR}" \
        | awk -F '|' '{printf("%-57s %-40s %-10s %-20s %-20s %-30s %-20s\n", $1, $2, $3, $4, $5, $6, $7 )}';
    glab mr list -P 1000 --output json \
        | jq '.[] | "\(.title)|\(.source_branch)|\(.target_branch)|\(.author.name)|\(.reviewers[0].name)|\(.merge_status)|\(.detailed_merge_status)"' \
        | sed -E 's/"//g' \
        | awk -F '|' '{printf("%-50s %-40s %-10s %-20s %-20s %-30s %-20s\n", $1, $2, $3, $4, $5, $6, $7 )}' \
        | stdout_buffer \
        | stdout_stripe;
}

gl_all_mrs () {
    # List all open GitLab merge requests for all local repos
    local cwd=`pwd`;
    for repo in $(gl_local_repos); do
        cd $PROJECTS_DIR/$repo;
        local table=`gl_mrs`;
        local result=`echo "$table" | wc -l`;
        if [ "$result" -ne "1" ]; then
            local REPO=`echo $repo | tr '[:lower:]' '[:upper:]'`;
            echo "${GREEN1}$REPO|${CLEAR}" \
                | awk -F '|' '{printf("%-200s %s\n", $1, $2)}' \
                | sed 's/ /-/g';
            echo $table;
            echo;
        fi;
    done;
    cd $cwd;
}

gl_jobs () {
    # List top 5 GitLab CI jobs for given repo
    # args: status, count
    local status_='.*';
    if [ "$1" ]; then status_=$1; fi;
    local count=5;
    if [ "$2" ]; then count=$2; fi;

    echo "${CYAN2}IID|STATUS|SOURCE|REF|CREATED_AT|WEB_URL${CLEAR}" \
        | awk -F '|' '{printf("%-13s %-10s %-20s %-31s %-27s %s\n", $1, $2, $3, $4, $5, $6)}';

    glab ci list -P $count --output json \
        | jq '.[] | "\(.iid)|\(.status)|\(.source)|\(.ref)|\(.created_at)|\(.web_url)"' \
        | sed -E 's/"//g' \
        | awk -F '|' '{printf("%-6s %-10s %-20s %-31s %-27s %s\n", $1, $2, $3, $4, $5, $6)}' \
        | grep -E $status_ \
        | stdout_buffer \
        | stdout_stripe;
}

gl_all_jobs () {
    # List top 5 GitLab CI jobs for all local repos
    # args: status, count
    local status_='.*';
    if [ "$1" ]; then status_=$1; fi;
    local count=5;
    if [ "$2" ]; then count=$2; fi;

    local cwd=`pwd`;
    cd $PROJECTS_DIR;
    for repo in $(gl_local_repos); do
        cd $PROJECTS_DIR/$repo;
        local jobs=`gl_jobs $status_ $count`;
        local result=`echo "$jobs" | wc -l`;
        if [ "$result" -ne "1" ]; then
            local REPO=`echo $repo | tr '[:lower:]' '[:upper:]'`;
            echo "${GREEN1}$REPO|${CLEAR}" \
                | awk -F '|' '{printf("%-200s %s\n", $1, $2)}' \
                | sed 's/ /-/g';
            echo $jobs;
            echo;
        fi;
    done;
    cd $cwd;
}

_gl_job_ids () {
    # Get all CI job IDs for the current repo
    local i=0;
    result=null;
    while [[ "$result" != "" ]]; do
        local result=`glab ci list --per-page 100 --page $i --output json | jq '.[].id';`;
        echo "$result";
        let "i+=1";
    done;
}

gl_job_data () {
    # Get all CI job data for the current repo
    get_job_data () {
        for jid in $(_gl_job_ids); do
            glab ci get --pipeline-id "$jid" --output json;
        done;
    };
    echo -n '[';
    get_job_data | tr '\n' ', ' | sed -E 's/,$//';
    echo -n ']';
}

_gl_settings () {
    # List GitLab settings of given repo directory
    # args: repo
    local repo='.';
    if [ "$1" ]; then local repo=$1; fi;
    local cwd=`pwd`;
    cd $repo;
    source $ZSH_SCRIPTS/misc_tools.sh;
    glab repo view --output json | flat_json;
    cd $cwd;
}

gl_settings () {
    # List GitLab settings of given repo directory
    # args: repo
    _gl_settings $1 | yq --prettyPrint | sort | yq;
}

gl_diff () {
    # Diff the GitLab settings of repo A with repo B, ignoring obviously different fields
    # args: repo a, repo b
    local regex="$1|$2|^id|_id|_at|avatar_url|description|/projects|star_count|build_timeout|import_(status|url|type)";
    local a=`gl_settings $1 | grep -vE "$regex"`;
    local b=`gl_settings $2 | grep -vE "$regex"`;
    local diff_=`diff <( printf '%s\n' "$a" ) <( printf '%s\n' "$b" )`;
    echo "$diff_" | grep -E '^>' | sed -E 's/^> +//' | sort;
}


_gl_settings_all () {
    # Create a table of all GitLab settings of all GitLab repos
    get_settings () {
        for repo in $(gl_local_repos); do
            _gl_settings "$repo";
        done;
    }
    cd $PROJECTS_DIR;
    echo -n '[';
    get_settings | tr '\n' ', ' | sed -E 's/,$//';
    echo -n ']';
}

gl_settings_all () {
    # Create a table of all GitLab settings of all GitLab repos
    _gl_settings_all | jq;
}

_gl_image_tags () {
    # Get all image tags for a given GitLab repo
    # args: repo
    local repo=`glab repo view $1 --output json`;
    local repo_id=`echo "$repo" | jq '.id'`;
    local reg_id=`glab api "projects/$repo_id/registry/repositories" | jq '.[0].id'`;
    if [ "$reg_id" = "null" ]; then
        return;
    fi;
    local head=`
        echo -n "$repo" \
            | jq -c 'with_entries(select([.key] | inside(["name", "id"])))' \
            | sed -E 's/"name"/"repo_name"/' \
            | sed -E 's/"id"/"repo_id"/' \
            | sed -E 's/\}//';
        echo ", \"registry_id\": $reg_id";
    `;
    local i=0;
    result=null;
    while [[ "$result" != "[]" ]]; do
        local result=`glab api "projects/$repo_id/registry/repositories/$reg_id/tags?per_page=100&page=$i"`;
        echo "$result" \
            | jq -c '.[]' \
            | jq -c 'with_entries(select([.key] | inside(["name", "path"])))' \
            | sed -E 's/"name"/"image_tag"/' \
            | sed -E 's/"path"/"image_path"/' \
            | sed -E 's/\{//' \
            | parallel "echo '$head, {}'" \
            | sed -E 's/\\//g';
        let "i+=1";
    done;
}

gl_image_tags () {
    # Get all image tags for a given GitLab repo
    # args: repo
    _gl_image_tags $1 | jq -c -M '.';
}

gl_pypi_package_versions () {
    # List all GitLab PyPI package versions
    # args: repo url
     local token=`cat $CREDS_DIR/gitlab-token.txt`;
     local proj_id=`glab repo view --output json $1 | jq '.id'`;
     glab api "https://__token__:$token@gitlab.com/api/v4/projects/$proj_id/packages" \
         | jq '.[].version' \
         | sed 's/"//g'
}
