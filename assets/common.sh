#!/usr/bin/env bash

# Copyright 2017, Z Lab Corporation. All rights reserved.
# Copyright 2017, kubernetes resource contributors
#
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.

# setup_kubectl prepares kubectl and exports the KUBECONFIG environment variable.
setup_kubectl() {
  local payload
  payload=$1

  local pks_endpoint
  pks_endpoint="$(jq -r '.source.pks_endpoint // ""' < "$payload")"
  
  local pks_user
  pks_endpoint="$(jq -r '.source.pks_user // ""' < "$payload")"
  

  local pks_password
  pks_cluster="$(jq -r '.source.pks_password // ""' < "$payload")"
  

  local pks_cluster
  pks_endpoint="$(jq -r '.source.pks_cluster // ""' < "$payload")"
  
  
  
  # Display the client and server version information
  exe kubectl version
  exe pks --version
 
  exe pks login -a ${pks_endpoint} -u ${pks_user} -p ${pks_password} -k
  exe pks get-credentials ${pks_cluster}
  # Ignore the error from `kubectl cluster-info`. From v1.9.0, this command
  # fails if it cannot find the cluster services.
  # See https://github.com/kubernetes/kubernetes/commit/998f33272d90e4360053d64066b9722288a25aae
  exe kubectl cluster-info 2>/dev/null ||:
}

# current_namespace outputs the current namespace.
current_namespace() {
  local namespace

  namespace="$(kubectl config view -o "jsonpath={.contexts[?(@.name==\"$(kubectl config current-context)\")].context.namespace}")"
  [[ -z "$namespace" ]] && namespace=default
  echo $namespace
}

# current_cluster outputs the address and port of the API server.
current_cluster() {
  local cluster

  cluster="$(kubectl config view -o "jsonpath={.contexts[?(@.name==\"$(kubectl config current-context)\")].context.cluster}")"
  kubectl config view -o "jsonpath={.clusters[?(@.name==\"${cluster}\")].cluster.server}"
}

# wait_until_pods_ready waits for all pods to be ready in the current
# namespace, which are excluded terminating and failed/succeeded pods.
# $1: The number of seconds that waits until all pods are ready.
# $2: The interval (sec) on which to check whether all pods are ready.
# $3: A label selector to identify a set of pods which to check whether those are ready. Defaults to every pods in the namespace.
wait_until_pods_ready() {
  local period interval selector template

  period="$1"
  interval="$2"
  selector="$3"

  echo "Waiting for pods to be ready for ${period}s (interval: ${interval}s, selector: ${selector:-''})"

  # The list of "<pod-name> <ready(True|False|`null`)>" which is excluded terminating and failed/succeeded pods.
  template="$(cat <<EOL
{{- range .items -}}
{{- if and (not .metadata.deletionTimestamp) (ne .status.phase "Failed") (ne .status.phase "Succeeded") -}}
{{.metadata.name}}{{range .status.conditions}}{{if eq .type "Ready"}} {{.status}}{{end}}{{end}}{{"\\n"}}
{{- end -}}
{{- end -}}
EOL
)"

  local statuses not_ready ready
  for ((i=0; i<period; i+=interval)); do
    sleep "$interval"

    statuses="$(kubectl get po --selector="$selector" -o template --template="$template")"
    # Some pods don't have "Ready" condition, so we can't determine "not Ready" using "False".
    not_ready="$(echo -n "$statuses" | grep -v -c "True" ||:)"
    ready="$(echo -n "$statuses" | grep -c "True" ||:)"

    echo "Waiting for pods to be ready... ($ready/$((not_ready + ready)))"

    if [[ "$not_ready" -eq 0 ]]; then
      return 0
    fi
  done

  echo "Waited for ${period}s, but the following pods are not ready yet."
  echo "$statuses" | awk '{if ($2 != "True") print "- " $1}'
  return 1
}

# echoerr prints an error message in red color.
echoerr() {
  echo -e "\\e[01;31mERROR: $*\\e[0m"
}

# exe executes the command after printing the command trace to stdout
exe() {
  echo "+ $*"; "$@"
}

# on_exit prints the last error code if it isning  0.
on_exit() {
  local code

  code=$?
  [[ $code -ne 0 ]] && echo && echoerr "Failed with error code $code"
  return $code
}
# vim: ai ts=2 sw=2 et sts=2 ft=sh
