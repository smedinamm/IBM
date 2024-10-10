#!/bin/bash
export HOME_REGISTRY=/opt/registry
#mkdir -p $HOME_REGISTRY/cpd-cli
#cd $HOME_REGISTRY/cdp-cli
#wget https://github.com/IBM/cpd-cli/releases/download/v13.0.4/cpd-cli-linux-EE-13.0.4.tgz
#tar -xvf cpd-cli-linux-EE-13.0.3.tgz
export PATH=$HOME_REGISTRY/cpd-cli/cpd-cli-linux-EE-13.0.4-59:$PATH
export CPD_CLI_MANAGE_WORKSPACE=$HOME_REGISTRY/cpd-cli/cpd-cli-workspace

#===============================================================================
# Cloud Pak for Data installation variables
#===============================================================================
# ------------------------------------------------------------------------------
# Client workstation 
# ------------------------------------------------------------------------------
# Set the following variables if you want to override the default behavior of the Cloud Pak for Data CLI.
#
# To export these variables, you must uncomment each command in this section.

# export CPD_CLI_MANAGE_WORKSPACE=<enter a fully qualified directory>
# export OLM_UTILS_LAUNCH_ARGS=<enter launch arguments>
# ------------------------------------------------------------------------------
# Cluster
# ------------------------------------------------------------------------------
export OCP_URL=https://api.clcstmdmprod.bacmdmprd.com:6443
export OPENSHIFT_TYPE=self-managed
export IMAGE_ARCH=amd64
export OCP_USERNAME=kubeadmin
export OCP_PASSWORD=vfogA-DrGix-WPrvo-uuMgj
# export OCP_TOKEN=<enter your token>
export SERVER_ARGUMENTS="--server=${OCP_URL}"
export LOGIN_ARGUMENTS="--username=${OCP_USERNAME} --password=${OCP_PASSWORD}"
# export LOGIN_ARGUMENTS="--token=${OCP_TOKEN}"
export CPDM_OC_LOGIN="cpd-cli manage login-to-ocp ${SERVER_ARGUMENTS} ${LOGIN_ARGUMENTS}"
export OC_LOGIN="oc login ${OCP_URL} ${LOGIN_ARGUMENTS}"

# ------------------------------------------------------------------------------
# Projects
# ------------------------------------------------------------------------------
export PROJECT_CERT_MANAGER=ibm-cert-manager
export PROJECT_LICENSE_SERVICE=ibm-licensing
export PROJECT_SCHEDULING_SERVICE=cpd-scheduler
export PROJECT_CPD_INST_OPERATORS=cp4d
export PROJECT_CPD_INST_OPERANDS=cp4d-operands
# export PROJECT_CPD_INSTANCE_TETHERED=<enter your tethered project>
# export PROJECT_CPD_INSTANCE_TETHERED_LIST=<a comma-separated list of tethered projects>

# ------------------------------------------------------------------------------
# Storage
# ------------------------------------------------------------------------------
export STG_CLASS_BLOCK=ocs-storagecluster-ceph-rbd
export STG_CLASS_FILE=ocs-storagecluster-cephfs

# ------------------------------------------------------------------------------
# IBM Entitled Registry
# ------------------------------------------------------------------------------
#export IBM_ENTITLEMENT_KEY=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJJQk0gTWFya2V0cGxhY2UiLCJpYXQiOjE2NTA2NDE0NDAsImp0aSI6IjIyNDc4YzU2NGI5YjQzMjFhZGQ1OTFiZThkYTE0NzUyIn0.DjP--bsdDUoJLOuUkVZngs4GIfV-7iotGSjeyql4Cs8
export IBM_ENTITLEMENT_KEY=eyJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJJQk0gTWFya2V0cGxhY2UiLCJpYXQiOjE1Nzk4OTcwMTQsImp0aSI6IjY3YWI3MThhZjRiOTQyYzRhMWUxNWM1ODJkMzI1NGRhIn0.E4cYz6VINGEgI5f_Z47D2mZr8Gsy3GjxMmnIVF5E7AI

# ------------------------------------------------------------------------------
# Private container registry
# ------------------------------------------------------------------------------
# Set the following variables if you mirror images to a private container registry.
#
# To export these variables, you must uncomment each command in this section.
export PRIVATE_REGISTRY_LOCATION=clcstmdmbastiop.bacmdmprd.com:5000
export PRIVATE_REGISTRY_PUSH_USER=admin
export PRIVATE_REGISTRY_PUSH_PASSWORD=passw0rd
export PRIVATE_REGISTRY_PULL_USER=admin
export PRIVATE_REGISTRY_PULL_PASSWORD=passw0rd

# ------------------------------------------------------------------------------
# Cloud Pak for Data version
# ------------------------------------------------------------------------------

export VERSION=4.7.4

# ------------------------------------------------------------------------------
# Components
# ------------------------------------------------------------------------------

export COMPONENTS=ibm-cert-manager,ibm-licensing,scheduler,cpfs,cpd_platform,cognos_analytics,wkc,db2wh,datastage_ent_plus,dmc,db2oltp 
# export COMPONENTS_TO_SKIP=<component-ID-1>,<component-ID-2>

cpd-cli manage restart-container
#cpd-cli manage save-image --from=icr.io/cpopen/cpd/olm-utils-v2:latest

cpd-cli manage login-entitled-registry ${IBM_ENTITLEMENT_KEY}
cpd-cli manage login-private-registry ${PRIVATE_REGISTRY_LOCATION} ${PRIVATE_REGISTRY_PUSH_USER} ${PRIVATE_REGISTRY_PUSH_PASSWORD}
cpd-cli manage list-images --components=${COMPONENTS} --release=${VERSION} --inspect_source_registry=true

# Mirroring Images
cpd-cli manage mirror-images --components=${COMPONENTS} --release=${VERSION} --target_registry=${PRIVATE_REGISTRY_LOCATION} --case_download=false
cpd-cli manage list-images --components=${COMPONENTS} --release=${VERSION} --target_registry=${PRIVATE_REGISTRY_LOCATION} --case_download=false
grep "level=fatal" $CPD_CLI_MANAGE_WORKSPACE/work/offline/${VERSION}/list_images.csv

#configure imagecontentSourcepolicy
cpd-cli manage login-to-ocp --username=${OCP_USERNAME} --password=${OCP_PASSWORD} --server=${OCP_URL}
cpd-cli manage apply-icsp --registry=${PRIVATE_REGISTRY_LOCATION}

#pulling OLM-utils
#export OLM_UTILS_IMAGE=${PRIVATE_REGISTRY_LOCATION}/cpopen/cpd/olm-utils-v2:${VERSION}
cpd-cli manage add-cred-to-global-pull-secret --registry=${PRIVATE_REGISTRY_LOCATION} --registry_pull_user=${PRIVATE_REGISTRY_PULL_USER} --registry_pull_password=${PRIVATE_REGISTRY_PULL_PASSWORD}
cpd-cli manage oc get nodes

oc new-project ${PROJECT_CERT_MANAGER}
oc new-project ${PROJECT_LICENSE_SERVICE}
oc new-project ${PROJECT_SCHEDULING_SERVICE}
cpd-cli manage login-to-ocp --username=${OCP_USERNAME} --password=${OCP_PASSWORD} --server=${OCP_URL}
cpd-cli manage apply-cluster-components --release=${VERSION} --license_acceptance=true --cert_manager_ns=${PROJECT_CERT_MANAGER} --licensing_ns=${PROJECT_LICENSE_SERVICE}
cpd-cli manage apply-scheduler --release=${VERSION} --license_acceptance=true --scheduler_ns=${PROJECT_SCHEDULING_SERVICE}

##### Manually creating projects
oc new-project ${PROJECT_CPD_INST_OPERATORS}
oc new-project ${PROJECT_CPD_INST_OPERANDS}
cpd-cli manage authorize-instance-topology --cpd_operator_ns=${PROJECT_CPD_INST_OPERATORS} --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}


export INSTANCE_ADMIN=OficialCP4D_Admin@baccredomatic.com
oc adm policy add-role-to-user admin ${INSTANCE_ADMIN} --namespace=${PROJECT_CPD_INST_OPERATORS} --rolebinding-name="cpd-instance-admin-rbac"
oc adm policy add-role-to-user admin ${INSTANCE_ADMIN} --namespace=${PROJECT_CPD_INST_OPERANDS} --rolebinding-name="cpd-instance-admin-rbac"

oc apply -f - << EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: cpd-instance-admin-apply-olm
  namespace: ${PROJECT_CPD_INST_OPERATORS}
rules:
- apiGroups:
  - operators.coreos.com
  resources:
  - operatorgroups
  verbs:
  - create
  - get
  - list
  - patch
  - update
- apiGroups:
  - operators.coreos.com
  resources:
  - catalogsources
  verbs:
  - create
  - get
  - list
EOF

oc adm policy add-role-to-user cpd-instance-admin-apply-olm ${INSTANCE_ADMIN} --namespace=${PROJECT_CPD_INST_OPERATORS} --role-namespace=${PROJECT_CPD_INST_OPERATORS} --rolebinding-name="cpd-instance-admin-apply-olm-rbac"

######## INSTALLATION ########

#foundational-services
cpd-cli manage login-to-ocp --username=${OCP_USERNAME} --password=${OCP_PASSWORD} --server=${OCP_URL}
cpd-cli manage setup-instance-topology --release=${VERSION} --cpd_operator_ns=${PROJECT_CPD_INST_OPERATORS} --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --license_acceptance=true

## db2
oc apply -f - <<EOF
apiVersion: v1
data:
  DB2U_RUN_WITH_LIMITED_PRIVS: "false"
kind: ConfigMap
metadata:
  name: db2u-product-cm
  namespace: ${PROJECT_CPD_INST_OPERATORS}
EOF
####### falta definir archivo de configuracion para el watson 

####### Cloudpak for data
cpd-cli manage login-to-ocp --username=${OCP_USERNAME} --password=${OCP_PASSWORD} --server=${OCP_URL}
cpd-cli manage get-license --release=${VERSION} --license-type=EE
cpd-cli manage apply-olm --release=${VERSION} --cpd_operator_ns=${PROJECT_CPD_INST_OPERATORS} --components=${COMPONENTS}

##### sin archivo de configuracion
#cpd-cli manage apply-cr --release=${VERSION} --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --components=${COMPONENTS} --block_storage_class=${STG_CLASS_BLOCK} --file_storage_class=${STG_CLASS_FILE} --license_acceptance=true

### con archivo de configuracion para el watson
cpd-cli manage apply-cr --release=${VERSION} --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --components=${COMPONENTS} --block_storage_class=${STG_CLASS_BLOCK} --file_storage_class=${STG_CLASS_FILE} --license_acceptance=true --param-file=/tmp/work/install-options.yml

cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
cpd-cli manage get-cpd-instance-details --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --get_admin_initial_credentials=true
