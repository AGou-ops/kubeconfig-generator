## Quickly start

```bash
 ./kubeconfig-generator.sh -u <USER_NAME> -g <GROUP> -d <CERTS_DIR> -s https://<API_SERVER_ADDRESS>:6443
```

sample:

```bash
 ./kubeconfig-generator.sh -u joe@example.com -d /Users/foo/.ansible/workspace/k8s/certs -s https://10.0.0.1:6443
⚙️  Checking CA certificates...
⚙️  Creating user directory: ./joe@example.com
⚙️  Generating private key...
⚙️  Generating CSR (Certificate Signing Request)...
⚙️  Signing certificate with Kubernetes CA...
⚙️  Creating kubeconfig file...
⚙️  Setting user credentials...
⚙️  Setting kubeconfig context...
✅ Kubeconfig file generated: joe@example.com.kubeconfig

# use kubeconfig via env
KUBECONFIG=./joe@example.com.kubeconfig kubectl get po
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
