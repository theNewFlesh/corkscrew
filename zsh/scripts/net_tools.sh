net_delete_known_host () {
    # Delete problematic host from ~/.known_hosts
    # args: host
    local line=$(ssh $1 2>&1 | grep Offending | sed -E 's/.*:(.*)/\1\td/' | tr -d '[:space:]');
    sed -i -e $line ~/.ssh/known_hosts;
}

net_config_ip () {
    # Get IP of given hostname in ~/.ssh/config
    # args: hostname
    cat ~/.ssh/config | grep $1 -A 2 | grep -i hostname | awk '{print $2}';
}

net_config_ips () {
    # Echoes all IPs in ~/.ssh/config
    cat ~/.ssh/config \
        | grep Host \
        | tr '\n' ' ' \
        | sed -E 's/Host /\n/g' \
        | sed 's/Hostname//g' \
        | awk '{printf("%-15s %s\n", $1, $2)}' \
        | sort \
        | grep -vE '^ *$';
}

net_config_name () {
    # Get hostname of given IP found in ~/.ssh/config
    # args: ip
    cat ~/.ssh/config | grep $1 -B 2 | grep -i 'host ' | awk '{print $2}';
}

net_post_json () {
    # Curl post JSON content
    # args: url, json data
    curl -s -H "Content-Type: application/json" $1 --data $2;
}

net_interfaces () {
    # List all ip addr interfaces in a simple table
    echo -n "${CYAN}INTERFACE                 STATE      IP${CLEAR}";
    ip addr \
        | sed -E 's/^.*: (.*:).*state( [A-Z]+ )/{\1 \2}/g' \
        | tr '\n' ' ' \
        | tr '{' '\n' \
        | sed -E 's/inet6.*/ /g' \
        | sed -E 's/\}.*inet/ /g' \
        | sed -E 's/\}.*|://g' \
        | awk '{printf("%-25s %-10s %s\n", $1, $2, $3)}' \
        | sort;
}

net_table () {
    # List nmap results of given subnet in a simple table
    # args: subnet
    echo "${CYAN}IP                   HOSTNAME                                 STATE      LATENCY${CLEAR}";
    nmap -sn $1/24 \
        | grep -E 'Nmap scan|Host is' \
        | tr '\n' ' ' \
        | sed 's/Nmap scan report for /\n/g' \
        | grep -vE '^$' \
        | sed -E 's/Host is |latency//g' \
        | sed -E 's/\(|\)\.?//g' \
        | sed -E 's/^([0-9\.]+ +.* +.*)$/NULL \1/' \
        | awk '{printf("%-20s %-40s %-10s %-10s\n", $2, $1, $3, $4)}' \
        | sed 's/NULL/    /';
}
