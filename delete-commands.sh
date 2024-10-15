#!/bin/bash
${OC_LOGIN}
oc get pv | grep Released | awk '{print $1}' | xargs oc delete pv
oc get scc | grep ${PROJECT_CPD_INST_OPERANDS} | awk '{print $1}' | xargs oc delete scc
oc project ${PROJECT_CPD_INST_OPERANDS}
while read -r resource_type
do
    echo "${resource_type}"
    while read -r resource
    do
        if [ -z "${resource}" ]; then
            continue
        fi
        kubectl delete "${resource}" -n "${PROJECT_CPD_INST_OPERANDS}" --timeout=10s \
        || kubectl patch "${resource}" -n "${PROJECT_CPD_INST_OPERANDS}" \
            --type=merge \
            --patch '{"metadata":{"finalizers":[]}}'
    done <<< "$(kubectl get "${resource_type}" -n "${PROJECT_CPD_INST_OPERANDS}" -o name  | sort)"
done <<< "$(kubectl api-resources --namespaced=true -o name | grep ibm.com | sort)"
oc delete project ${PROJECT_CPD_INST_OPERANDS}
oc get project ${PROJECT_CPD_INST_OPERANDS} -o yaml
oc project ${PROJECT_CPD_INST_OPERATORS}
while read -r resource_type
do
    echo "${resource_type}"
    while read -r resource
    do
        if [ -z "${resource}" ]; then
            continue
        fi
        kubectl delete "${resource}" -n "${PROJECT_CPD_INST_OPERATORS}" --timeout=10s \
        || kubectl patch "${resource}" -n "${PROJECT_CPD_INST_OPERATORS}" \
            --type=merge \
            --patch '{"metadata":{"finalizers":[]}}'
    done <<< "$(kubectl get "${resource_type}" -n "${PROJECT_CPD_INST_OPERATORS}" -o name  | sort)"
done <<< "$(kubectl api-resources --namespaced=true -o name | grep ibm.com | sort)"
oc delete project ${PROJECT_CPD_INST_OPERATORS}
