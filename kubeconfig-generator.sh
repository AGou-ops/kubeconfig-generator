#!/usr/bin/env bash

CYAN='\033[1;36m'
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

USER=""
GROUP=""
CERT_DIR="/etc/kubernetes/pki"
KUBE_API_SERVER=""

usage() {
    echo -e "${YELLOW}Usage:${NC} $0 -u <user> -s <api-server> [-g <group>] [-d <cert-dir>]"
    echo -e "\n${YELLOW}Options:${NC}"
    echo -e "  -u    Specify the username (required)"
    echo -e "  -s    Specify the Kubernetes API server URL (required)"
    echo -e "  -g    Specify the user group (optional)"
    echo -e "  -d    Specify the directory containing CA certificates (default: /etc/kubernetes/pki)"
    echo -e "  -h    Display this help message"
    exit 0
}

while getopts "u:g:d:s:h" opt; do
    case $opt in
        u) USER=$OPTARG ;;
        g) GROUP=$OPTARG ;;
        d) CERT_DIR=$OPTARG ;;
        s) KUBE_API_SERVER=$OPTARG ;;
        h) usage ;;
        *)
            echo -e "${RED}Invalid option: -$OPTARG${NC}"
            usage
            ;;
    esac
done

if [[ -z "$USER" || -z "$KUBE_API_SERVER" ]]; then
    echo -e "${RED}Error: User and API server are required.${NC}"
    usage
fi

CLUSTER_NAME="k8s-cluster-$USER"

echo -e "⚙️  ${CYAN}Checking CA certificates...${NC}"
if [[ -f "$CERT_DIR/ca.crt" ]]; then
    CA_CERT="$CERT_DIR/ca.crt"
elif [[ -f "$CERT_DIR/ca.pem" ]]; then
    CA_CERT="$CERT_DIR/ca.pem"
else
    echo -e "${RED}Error: CA certificate not found in $CERT_DIR (expected ca.crt or ca.pem)${NC}"
    exit 1
fi

if [[ ! -f "$CERT_DIR/ca.key" ]]; then
    echo -e "${RED}Error: CA key not found in $CERT_DIR${NC}"
    exit 1
fi

USER_DIR="./$USER"
echo -e "⚙️  ${CYAN}Creating user directory: $USER_DIR${NC}"
mkdir -p "$USER_DIR"

echo -e "⚙️  ${CYAN}Generating private key...${NC}"
openssl genrsa -out "$USER_DIR/$USER.key" 2048 >/dev/null 2>&1

echo -e "⚙️  ${CYAN}Generating CSR (Certificate Signing Request)...${NC}"
if [[ -z "$GROUP" ]]; then
    openssl req -new -key "$USER_DIR/$USER.key" -out "$USER_DIR/$USER.csr" -subj "/CN=$USER" >/dev/null 2>&1
else
    openssl req -new -key "$USER_DIR/$USER.key" -out "$USER_DIR/$USER.csr" -subj "/CN=$USER/O=$GROUP" >/dev/null 2>&1
fi

echo -e "⚙️  ${CYAN}Signing certificate with Kubernetes CA...${NC}"
openssl x509 -req -in "$USER_DIR/$USER.csr" -CA "$CA_CERT" -CAkey "$CERT_DIR/ca.key" -CAcreateserial -out "$USER_DIR/$USER.crt" -days 365 >/dev/null 2>&1

echo -e "⚙️  ${CYAN}Creating kubeconfig file...${NC}"
KUBECONFIG_FILE="$USER.kubeconfig"

kubectl config set-cluster "$CLUSTER_NAME" \
    --server="$KUBE_API_SERVER" \
    --certificate-authority="$CA_CERT" \
    --kubeconfig="$KUBECONFIG_FILE" >/dev/null 2>&1

echo -e "⚙️  ${CYAN}Setting user credentials...${NC}"
kubectl config set-credentials "$USER" \
    --client-certificate="$USER_DIR/$USER.crt" \
    --client-key="$USER_DIR/$USER.key" \
    --kubeconfig="$KUBECONFIG_FILE" >/dev/null 2>&1

echo -e "⚙️  ${CYAN}Setting kubeconfig context...${NC}"
kubectl config set-context "$USER-context" \
    --cluster="$CLUSTER_NAME" \
    --user="$USER" \
    --kubeconfig="$KUBECONFIG_FILE" >/dev/null 2>&1

kubectl config use-context "$USER-context" --kubeconfig="$KUBECONFIG_FILE" >/dev/null 2>&1

echo -e "✅ ${GREEN}Kubeconfig file generated: $KUBECONFIG_FILE${NC}"
