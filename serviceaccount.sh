# This is the script for creating service account in kubernetes all steps are automated and just provide the inputs which are requires to create service account

#!/bin/bash

# === Ask user for inputs ===
read -p "Enter the ServiceAccount name: " SA_NAME
read -p "Enter the Namespace: " NAMESPACE
read -p "Enter the kubeconfig username: " KUBECONFIG_USER
read -p "Enter the context name: " CONTEXT_NAME

SECRET_NAME="${SA_NAME}-token"

# === Create the ServiceAccount ===
echo "Creating ServiceAccount $SA_NAME in namespace $NAMESPACE..."
kubectl get sa "$SA_NAME" -n "$NAMESPACE" >/dev/null 2>&1 || \
kubectl create sa "$SA_NAME" -n "$NAMESPACE"

# === Create the Token Secret ===
echo "Creating token Secret $SECRET_NAME..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: $SECRET_NAME
  namespace: $NAMESPACE
  annotations:
    kubernetes.io/service-account.name: "$SA_NAME"
type: kubernetes.io/service-account-token
EOF

# === Wait for token to be available ===
echo "Waiting for token to be generated..."
sleep 5  # Token may take a few seconds to populate

# === Extract token, CA, and cluster endpoint ===
echo "Extracting credentials..."
TOKEN=$(kubectl get secret $SECRET_NAME -n $NAMESPACE -o jsonpath='{.data.token}' | base64 --decode)
CA_CRT=$(kubectl get secret $SECRET_NAME -n $NAMESPACE -o jsonpath='{.data.ca\.crt}' | base64 --decode)
CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')
CLUSTER_ENDPOINT=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')

# === Add user and context to kubeconfig ===
echo "Adding new user '$KUBECONFIG_USER' to kubeconfig..."
kubectl config set-credentials $KUBECONFIG_USER --token="$TOKEN"

echo "Setting new context '$CONTEXT_NAME'..."
kubectl config set-context $CONTEXT_NAME \
  --cluster="$CLUSTER_NAME" \
  --user="$KUBECONFIG_USER" \
  --namespace="$NAMESPACE"

# === Switch context ===
kubectl config use-context $CONTEXT_NAME

echo -e "\n✅ Done! Now using context '$CONTEXT_NAME' with ServiceAccount '$SA_NAME'."
