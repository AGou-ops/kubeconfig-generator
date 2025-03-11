## Quickly start

```bash
 ./kubeconfig-generator.sh -u <USER_NAME> -g <GROUP> -d <CERTS_DIR> -s https://<API_SERVER_ADDRESS>:6443
```

help:

```bash
./kubeconfig-generator.sh -u <user> -s <api-server> [-g <group>] [-d <cert-dir>]

Options:
  -u    Specify the username (required)
  -s    Specify the Kubernetes API server URL (required)
  -g    Specify the user group (optional)
  -d    Specify the directory containing CA certificates (default: /etc/kubernetes/pki)
  -h    Display this help message

```
