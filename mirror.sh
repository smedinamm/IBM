#!/bin/bash
echo "###############################################################################################"
echo "########## Bienvenido al script de ejecucion de instalador de Openshift en Azure (IaaS) #######"
echo "###############################################################################################"
echo " Antes de iniciar recuerde descargar su archivo pullsecret en $HOME, guardelo con el nombre pullsecret.txt"
read -p "Cuenta con su archivo en el directorio mencionado? si/no R:/" iniciar
echo ""

install_mirror () {
# Install paquetes
typeset -l SO=$(cat /etc/os-release | grep ^ID= | cut -d'"' -f2)
if [ $SO == "ubuntu" ]; then
  sudo apt update -y
  sudo apt install apache2-utils -y
  sudo apt install jq -y
  sudo apt install podman -y
elif [ $SO == "rhel" ]; then
  sudo yum repolist -y
  sudo dnf list podman -y
  sudo dnf install -y podman
  sudo dnf install httpd-tools -y
  sudo dnf install -y jq
fi
# Generar Keygen
ssh-keygen -t ed25519 -N ''
# creacion de directorios mirror
export HOME_MIRROR=/opt
sudo mkdir -p $HOME_MIRROR/registry/{auth,certs,data}
sudo chown -R root:root $HOME_MIRROR/registry

echo " ingrese el private dns zone de su bastion \n"
read -p "private DNS Zone: " pvdns
echo $pvdns
rightpvdns="$pvdns"
rightHOSTNAME="$HOSTNAME"
# generacion de certificado 
cat << EOF > $HOME_MIRROR/registry/certs/cert.conf
[ req ]
default_bits = 2048
default_keyfile = key.pem
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[ req_distinguished_name ]
C = CR
ST = San Jose
L = San Jose
O = GBM
OU = Software
CN = registry

[ v3_req ]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
basicConstraints = CA:TRUE
authorityKeyIdentifier = keyid,issuer

[ alt_names ]
DNS.1 = localhost
DNS.2 = registry
DNS.3 = $rightHOSTNAME
DNS.4 = registry.$rightpvdns
DNS.5 = $rightHOSTNAME.$rightpvdns
IP.1 = 127.0.0.1
EOF
cd $HOME_MIRROR/registry/certs
openssl req -newkey rsa:4096 -nodes -sha256 -keyout server.key -x509 -days 3650 -out server.crt -config cert.conf -extensions v3_req
# crear htpasswd
htpasswd -bBc $HOME_MIRROR/registry/auth/htpasswd admin passw0rd
cd $HOME

if [ $SO == "ubuntu" ]; then
  sudo cp $HOME_MIRROR/registry/certs/server.crt /usr/local/share/ca-certificates/server.crt
  sudo update-ca-certificates
elif [ $SO == "rhel" ]; then
  sudo cp $HOME_MIRROR/registry/certs/server.crt /etc/pki/ca-trust/source/anchors/
  sudo update-ca-trust
fi
podman run --name mirror-registry -p 5000:5000 -v $HOME_MIRROR/registry/data:/var/lib/registry:z -v $HOME_MIRROR/registry/auth:/auth:z -e "REGISTRY_AUTH=htpasswd" -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd -v $HOME_MIRROR/registry/certs:/certs:z -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/server.crt -e REGISTRY_HTTP_TLS_KEY=/certs/server.key -d  docker.io/library/registry:2

echo "#### Listado de Containers PODMAN ####\n ################################\n"
podman ps 

cat pullsecret.txt | jq . > pull-secret.json
cat pull-secret.json

podman login --authfile pull-secret.json $HOSTNAME.$pvdns:5000 --username admin --password passw0rd
cp pull-secret.json $XDG_RUNTIME_DIR/containers/auth.json
REG_CREDS=${XDG_RUNTIME_DIR}/containers/auth.json

export OCP_RELEASE=4.12.35
export LOCAL_REGISTRY=$HOSTNAME.$pvdns:5000
export LOCAL_REPOSITORY='ocp4/openshift4'
export PRODUCT_REPO='openshift-release-dev'
export LOCAL_SECRET_JSON=$HOME/pull-secret.json
export RELEASE_NAME="ocp-release"
export ARCHITECTURE='x86_64'

# oc adm release mirror -a ${LOCAL_SECRET_JSON} --from=quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE} --to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} --to-release-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE} --dry-run
oc adm release mirror -a ${LOCAL_SECRET_JSON} --from=quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE} --to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} --to-release-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE}
oc adm release extract -a ${LOCAL_SECRET_JSON} --command=openshift-install "${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE}"
}

if [ $iniciar == "si" ]; then
  install_mirror
elif [ $iniciar == "no" ]; then
  echo "Favor realice el cargue de su archivo pullsecret.txt antes de iniciar y ejecute de nuevo el script.\n"
fi
