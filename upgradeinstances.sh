------upgrade instances cognos -----
cpd-cli config users list --output=table
export API_KEY=dzQsjCRGfs4Uic96ryrVoqypukDpCYujTlKISLfZ
export CPD_USERNAME=admin
export LOCAL_USER=root
export CPD_PROFILE_NAME=default

oc get route cpd \
--namespace=${PROJECT_CPD_INST_OPERANDS}

export CPD_PROFILE_URL=https://cpd-cp4d-operands.apps.clustername.private.gbmtest.com
export CPD_PROFILE_URL=https://cpd-cp4d-operands.apps.clusterrespaldo.private.gbmtest.com

cpd-cli config users set ${LOCAL_USER} \
--username ${CPD_USERNAME} \
--apikey ${API_KEY}

cpd-cli config profiles set ${CPD_PROFILE_NAME} \
--user ${LOCAL_USER} \
--url ${CPD_PROFILE_URL}

cpd-cli service-instance list --profile=${CPD_PROFILE_NAME}

## validar profiles y usuarios
cpd-cli user-mgmt list-users --profile ${CPD_PROFILE_NAME} --output type
cpd-cli config users list --output=table

#version 4.8.1
export INSTANCE_VERSION=25.0.0

#version 4.8.5
export INSTANCE_VERSION=25.4.0

cpd-cli service-instance upgrade \
--service-type=cognos-analytics-app \
--profile=${CPD_PROFILE_NAME} \
--version=${INSTANCE_VERSION} \
--all

--------------------------db2 4.8.1
oc get Db2uCluster
oc get db2ucluster <instance_id> -o yaml | grep version
##oc set volume statefulset/c-${DB2U_ID}-db2u -n ${PROJECT_CPD_INST_OPERANDS} --remove --name=<volume_name>
oc patch db2ucluster <instance_id> --type merge -p '{"spec":{"version":"<db2_version>"}}'

--------------------------db2 4.8.1
cpd-cli service-instance list --profile=${CPD_PROFILE_NAME} --service-type=db2oltp
cpd-cli service-instance upgrade --profile=${CPD_PROFILE_NAME} --instance-name=${INSTANCE_NAME} --service-type=db2oltp

-------spark
cpd-cli service-instance upgrade \
--service-type=spark \
--profile=${CPD_PROFILE_NAME} \
--all

--------datastage 4.7.4 to 4.8
oc -n ${PROJECT_CPD_INST_OPERANDS} get pxruntime \
| awk 'NR>1 { print $1 }' \
| xargs -I % oc -n ${PROJECT_CPD_INST_OPERANDS} patch pxruntime % --type=merge -p '{"spec":{"upgrade_force": true}}'

oc -n ${PROJECT_CPD_INST_OPERANDS} get pxruntime

oc -n ${PROJECT_CPD_INST_OPERANDS} get pxruntime \
| awk 'NR>1 { print $1 }' \
| xargs -I % oc -n ${PROJECT_CPD_INST_OPERANDS} patch pxruntime % --type='json' -p='[{"op": "remove", "path": "/spec/upgrade_force"}]'




-----------------------------------

for cluster in $(oc get cluster.postgresql -o name -n cp4d-operands);
do oc get $cluster -n cp4d-operands -ojsonpath='{.status.licenseStatus.licenseExpiration},{"\n"}{.status.licenseStatus.licenseStatus}{"\n"}';
done
#Option 2: Manual License Key Update
namespace=$(oc get job -A | grep create-postgres-license-config | awk '{print $1}')

oc get job create-postgres-license-config -n $namespace -o yaml | \
sed -e 's/operator.ibm.com\/opreq-control: "true"/operator.ibm.com\/opreq-control: "false"/' \
    -e 's|\(image: \).*|\1"cp.icr.io/cp/cpd/edb-postgres-license-provider@"sha256:5ea15c640c66100179c9f33161aa8af774075ba33a8463a837d75f4937f5bbb4"|' \
    -e '/controller-uid:/d' | \
oc replace --force -f - && \
oc wait --for=condition=complete job/create-postgres-license-config -n $namespace

oc get clusters.postgresql.k8s.enterprisedb.io zen-metastore-edb -n cp4d-operands  -o jsonpath='{.status.licenseStatus.licenseExpiration}, {"\n"}{.status.licenseStatus.licenseStatus}{"\n"}'

##cambio de imagen
podman login cp.icr.io -u cp -p 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJJQk0gTWFya2V0cGxhY2UiLCJpYXQiOjE2NTA2NDE0NDAsImp0aSI6IjIyNDc4YzU2NGI5YjQzMjFhZGQ1OTFiZThkYTE0NzUyIn0.DjP--bsdDUoJLOuUkVZngs4GIfV-7iotGSjeyql4Cs8'
podman pull cp.icr.io/cp/cpd/edb-postgres-license-provider@sha256:c1670e7dd93c1e65a6659ece644e44aa5c2150809ac1089e2fd6be37dceae4ce
IMAGE_ID=bf14e5dbbf3d
podman images |grep edb-postgres-license-provider
podman tag $IMAGE_ID cp.icr.io/cp/cpd/edb-postgres-license-provider:1600
podman push cp.icr.io/cp/cpd/edb-postgres-license-provider:1600 ${PRIVATE_REGISTRY_LOCATION}/cp/cpd/edb-postgres-license-provider:1600

podman push cp.icr.io/cp/cpd/edb-postgres-license-provider:1600 ${PRIVATE_REGISTRY_LOCATION}/cp/cpd/edb-postgres-license-provider:1600 --remove-signatures

skopeo inspect docker://${PRIVATE_REGISTRY_LOCATION}/cp/cpd/edb-postgres-license-provider:1600 --tls-verify=false

{
  "Name": "test:5000/cp/cpd/edb-postgres-license-provider",
  "Digest": "sha256:5ea15c640c66100179c9f33161aa8af774075ba33a8463a837d75f4937f5bbb4",
  "RepoTags": [
    "1600"
  ],
  "Created": "2024-05-07T10:25:34.699036409Z",
  .......
}
