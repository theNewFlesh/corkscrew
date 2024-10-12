# requires: parallel

f () {
    # Echo each item then apply given command to it
    # args: command with '{}'' in it
    # example: ls | f 'du sh {}'
    parallel "echo '$CYAN1{}$CLEAR'; $1; echo";
}

f_cat_all () {
    # Find all a files in given input and grep their contents
    # args: pattern
    parallel 'find {} -type f -maxdepth 0' \
        | f "cat {} 2>&1 | grep -E '$1'" \
        | grep -EB 1 "$1|^$" \
        | grep -vE "^\-\-$";
}

f_cat () {
    # Like f_cat_all but drops files that have no matching contents
    # args: pattern
    f_cat_all $1 | grep -EB 1 "$1" | sed 's/^--$//g';
}

f_find () {
    # Look for files in each given item that match grep pattern
    # args: gre pattern
    parallel "find {} | grep -E $1" | grep -EB 1 $1 | sed 's/^--$//g';
}

f_line () {
    # Like f but keeps output all in one line
    # args: commands with '{}' in it
    parallel "echo -n '{} '; $1"
}
