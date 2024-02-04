_k8s_get_context () {
    # Get kubectl context command string
    # args: context
    local context="";
    if [ "$1" ]; then
        local context=$1;
    else
        local context=`kubectl config get-contexts --output name`;
    fi;
    echo "--context $context";
}

_k8s_get_namespace () {
    # Get kubectl namespace command string
    # args: namespace
    if [ "$1" ]; then
        echo "--namespace $1";
    else
        echo "-A";
    fi;
}

k8s_get_resources () {
    # Get K8s resources matching grep pattern
    # args: pattern
    local resources=`\
        kubectl api-resources | awk '{print $1}' | grep -vE 'NAME|events'`;
    echo $resources \
        | sort \
        | uniq \
        | parallel "\
            echo -n '$CYAN1{}$CLEAR>>>'; \
            kubectl get {} -A 2> /dev/null | grep $1 | tr '\n' '>'; \
            echo" \
        | grep -vE '>>>$' \
        | sed -E 's/>>>/\n/' \
        | tr '>' '\n';
}

k8s_get_pods () {
    # Find all K8s pods under a given namespace and context
    # args: namespace, context
    local namespace=`_k8s_get_namespace $1`;
    local context=`_k8s_get_context $2`;
    local cmd=" \
        kubectl get pod \
            $namespace \
            $context \
            --output custom-columns=:.metadata.name \
        | grep -vE '^$' \
    ";
    eval $cmd;
}

k8s_get_pod () {
    # Find a specific pod name matching a grep pattern
    # args: pattern, namespace, context
    k8s_get_pods $2 $3 | grep -E $1;
}

k8s_ssh_pod () {
    # SSH into K8s pod matching given grep pattern
    # args: pattern, namespace, context
    local namespace=`_k8s_get_namespace $2`;
    local context=`_k8s_get_context $3`;
    local pod=`k8s_get_pod $1 $2 $3`;
    local cmd="\
        kubectl exec \
            --stdin \
            --tty \
            $namespace \
            $context \
            $pod -- sh \
    ";
    eval $cmd;
}

k8s_get_resources_with_finalizers () {
    # Find all K8s resources with finalizers
    # args: namespace, context, field
    local namespace=`_k8s_get_namespace $2`;
    local context=`_k8s_get_context $3`;
    local field=spec;
    if [ "$3" ]; then local field=$3; fi;
    local cmd=" \
        kubectl get all \
            $namespace \
            $context \
            -o custom-columns="kind:.kind,name:.metadata.name,finalizers:.$field.finalizers" \
    ";
    eval $cmd | grep -vE '<none>|^kind' | awk '{printf("%s/%s\n", $1, $2)}';
}

k8s_remove_finalizers () {
    # Remove finalizers from K8s resources under a given namespace
    # args: namespace, context, field
    local namespace=`_k8s_get_namespace $1`;
    local context=`_k8s_get_context $2`;
    k8s_get_resources_with_finalizers $@ \
        | grep -v Job \
        | f "kubectl patch {} \
            $namespace \
            $context \
            --patch '{\"metadata\": {\"finalizers\": null}}'";
}

k8s_remove_finalizer () {
    # Remove finalizer from given resource of given name
    # args: type, name, naemspace, context
    local namespace=`_k8s_get_namespace $3`;
    local context=`_k8s_get_context $4`;
    local cmd="kubectl get $1 $2 -o yaml $namespace $context";
    eval $cmd \
        | grep -E 'finalizers:' -B 1000 \
        | sed 's/finalizers:/finalizers: []/' \
        | yq e --tojson \
        | kubectl replace --raw "/api/v1/$1s/$2/finalize" -f -;
}

k8s_copy_to_pod () {
    # Copy given file to given K8s pod
    # args: file, pod, namespace, context
    local namespace=`_k8s_get_namespace $4`;
    local context=`_k8s_get_context $5`;
    local pod=`k8s_get_pod $3 $4 $5`;
    kubectl cp "$1" "$4/$pod:$2";
}
