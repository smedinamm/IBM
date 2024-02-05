#!/bin/bash
export OCP_URL=https://api.clustername.private.gbmtest.com:6443
export OPENSHIFT_TYPE=self-managed
export IMAGE_ARCH=amd64
export OCP_USERNAME=kubeadmin
export OCP_PASSWORD=jxqMz-Dvtqb-Go4bH-mianR
export SERVER_ARGUMENTS="--server=${OCP_URL}"
export LOGIN_ARGUMENTS="--username=${OCP_USERNAME} --password=${OCP_PASSWORD}"
export CPDM_OC_LOGIN="cpd-cli manage login-to-ocp ${SERVER_ARGUMENTS} ${LOGIN_ARGUMENTS}"
export OC_LOGIN="oc login ${OCP_URL} ${LOGIN_ARGUMENTS}"
export PROJECT_CPD_INST_OPERATORS=cp4d
export PROJECT_CPD_INST_OPERANDS=cp4d-operands

#### CP4D Control Plane
export SIZE=medium
oc patch zenservice lite-cr --namespace ${PROJECT_CPD_INST_OPERANDS} --type="json" --patch '[{"op": "replace", "path":"/spec/scaleConfig", "value":'${SIZE}' }]'
oc get zenservice lite-cr 
#dataManagement Console
export SIZE=small
oc patch dmc <dmcs_cr_name> --namespace ${PROJECT_CPD_INST_OPERANDS} --patch '{"spec":{"scaleConfig":"${SIZE}"}}' --type=merge
#datastage
export SIZE=medium
cpd-cli manage update-cr --component=datastage_ent --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --patch="{\"scaleConfig\":\"${SIZE}\"}"
#Watson knowledge catalog
export SIZE=small
cpd-cli manage update-cr --component=wkc --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --patch="{\"scaleConfig\":\"${SIZE}\"}"
#Analitics Engine power Spark
export SIZE=small
cpd-cli manage update-cr --component=analyticsengine --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --patch="{\"scaleConfig\":\"${SIZE}\"}"
#common Core services
export SIZE=medium
oc patch ccs ccs-cr --namespace ${PROJECT_CPD_INST_OPERANDS} --type="json" --patch '[{"op": "replace", "path":"/spec/scaleConfig", "value":'${SIZE}' }]'
#common databases services
No tiene
#foundationalservices
No tiene


#db2 warehouse
https://www.ibm.com/docs/en/cloud-paks/cp-data/4.7.x?topic=scaling-up


${OC_LOGIN}
export USER_EXPIRY_TIME=0.2
export ADMIN_EXPIRY_TIME=0.2
export USER_REFRESH_PERIOD=1
export ADMIN_REFRESH_PERIOD=1

oc patch configmap product-configmap --namespace=${PROJECT_CPD_INST_OPERANDS} --type=merge --patch="{\"data\": {\"TOKEN_EXPIRY_TIME\": \"${USER_EXPIRY_TIME}\"}}"
oc patch configmap product-configmap --namespace=${PROJECT_CPD_INST_OPERANDS} --type=merge --patch="{\"data\": {\"ADMIN_TOKEN_EXPIRY_TIME\": \"${ADMIN_EXPIRY_TIME}\"}}"
oc patch configmap product-configmap --namespace=${PROJECT_CPD_INST_OPERANDS} --type=merge --patch="{\"data\": {\"TOKEN_REFRESH_PERIOD": \"${USER_REFRESH_PERIOD}\"}}"
oc patch configmap product-configmap --namespace=${PROJECT_CPD_INST_OPERANDS} --type=merge --patch="{\"data\": {\"ADMIN_TOKEN_REFRESH_PERIOD": \"${ADMIN_REFRESH_PERIOD}\"}}"

oc delete pods --namespace=${PROJECT_CPD_INST_OPERANDS} -l component=usermgmt
