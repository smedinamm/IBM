#!/usr/bin/env bash
#
# -----------------------------------------------------------------------------
#         Licensed Materials - Property of IBM
#
#         IBM Cognos Products: ca
#
#         (C) Copyright IBM Corp. 2023
#
#         US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule
# -----------------------------------------------------------------------------
#
#

#set -e
#set -x

function usage {
    echo $0: usage: $0 [-h][-n namespace][-t cognos instance namespace]
}

function help {
    usage
    echo "-h                    prints help to the console"
    echo "-n namespace          cpd control plane namespace where ibm-cognos-addon-sp pod is running"
    echo "-t cognamespace       namespace where cognos instance pods are running"
    echo ""
    exit 0
}

while getopts ":h:n:t:" opt; do
     case ${opt} in
     h)
        help
        ;;
     n)
        _namespace=$OPTARG
        ;;
     t)
        _cognamespace=$OPTARG
        ;;
     \?)
        usage
        exit 0
        ;;
     esac
done
if [[ "$_namespace" == "" ]]; then
        usage
        exit 1
fi
if [[ "$_cognamespace" == "" ]]; then
        usage
        exit 1
fi
COGNAMESPACE=$_cognamespace
NAMESPACE=$_namespace
ROUTE=$(oc get route -n ${NAMESPACE} | grep ibm-nginx-svc | awk '{print $2}')
CPDURL="https://"$ROUTE
CPDAUTHURL=${CPDURL}/icp4d-api/v1/authorize
ZENURL=https://zen-core-api-svc.$NAMESPACE.svc:4444/v3/service_instances
USERNAME=admin
PASSWORD=$(oc extract secret/admin-user-details --keys=initial_admin_password --to=- -n "$NAMESPACE")

get_bearer_token_from_cpd() {
        local BEARER="$( curl -s -k -X POST -H 'Content-Type: application/json'  -d "{ \"username\":\"${USERNAME}\", \"password\":\"${PASSWORD}\" }" "$CPDAUTHURL" | jq -r '. | .token' )"
        echo "$BEARER"
}

  BEARER=$( get_bearer_token_from_cpd )
  JWT_TOKEN="Authorization: Bearer $BEARER"

  SP_CONTAINER=$(oc get po -n $NAMESPACE | grep ibm-cognos-addon-sp | awk '{print $1}')
  INSTANCE_ID=$(oc get po |grep artifacts |cut -d '-' -f1 |cut -d 'a' -f2)

  echo "Get instance $INSTANCE_ID status before:"
  oc exec -it $SP_CONTAINER -- curl -L "${ZENURL}/${INSTANCE_ID}" -H "$JWT_TOKEN" -k

  echo "Set instance $INSTANCE_ID status to PROVISIONED:"
  oc exec -it $SP_CONTAINER -- curl -X PATCH -L "${ZENURL}/${INSTANCE_ID}/meta" -H "$JWT_TOKEN" -k -H 'Content-Type: application/json' -d '{ "provision_status": "PROVISIONED", "service_instance_version": "23.5.0" }'

  echo "Get instance $INSTANCE_ID status after:"
  oc exec -it $SP_CONTAINER -- curl -L "${ZENURL}/${INSTANCE_ID}" -H "$JWT_TOKEN" -k
