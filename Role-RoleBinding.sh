## After creating service account this is the script to create ROle-Rolebinding both cluster or namespace scoped, just provide the imput you want to add in that manifests,


#!/bin/bash

echo "=== Kubernetes ServiceAccount + Role/RoleBinding Creator ==="

# --- Inputs ---
read -p "Enter the ServiceAccount name: " SA_NAME
read -p "Enter the Namespace: " NAMESPACE

# Ask if it's a Role (namespace-scoped) or ClusterRole (cluster-wide)
echo "Choose Role Type:"
echo "1) Role (namespace-scoped)"
echo "2) ClusterRole (cluster-wide)"
read -p "Enter 1 or 2: " ROLE_TYPE_CHOICE

if [ "$ROLE_TYPE_CHOICE" == "1" ]; then
  ROLE_TYPE="Role"
  BINDING_TYPE="RoleBinding"
else
  ROLE_TYPE="ClusterRole"
  BINDING_TYPE="ClusterRoleBinding"
fi

read -p "Enter a name for the $ROLE_TYPE: " ROLE_NAME

# Verb options
echo "Choose verbs (separate multiple choices with space):"
echo "1) get"
echo "2) list"
echo "3) watch"
echo "4) create"
echo "5) update"
echo "6) patch"
echo "7) delete"
read -p "Enter numbers (e.g., 1 2 4 7): " VERB_CHOICES

# Map choices to verbs
VERBS=()
for choice in $VERB_CHOICES; do
  case $choice in
    1) VERBS+=("get");;
    2) VERBS+=("list");;
    3) VERBS+=("watch");;
    4) VERBS+=("create");;
    5) VERBS+=("update");;
    6) VERBS+=("patch");;
    7) VERBS+=("delete");;
    *) echo "Invalid choice: $choice";;
  esac
done

# Resources
read -p "Enter the Kubernetes resources (e.g., pods, deployments, secrets): " RESOURCES

# --- Generate YAML ---
ROLE_FILE="${ROLE_NAME}.yaml"

cat <<EOF > $ROLE_FILE
apiVersion: rbac.authorization.k8s.io/v1
kind: $ROLE_TYPE
metadata:
  name: $ROLE_NAME
  namespace: $NAMESPACE
rules:
- apiGroups: [""]
  resources: [$RESOURCES]
  verbs: [$(printf '"%s", ' "${VERBS[@]}" | sed 's/, $//')]
EOF

cat <<EOF >> $ROLE_FILE

---
apiVersion: rbac.authorization.k8s.io/v1
kind: $BINDING_TYPE
metadata:
  name: ${ROLE_NAME}-binding
  namespace: $NAMESPACE
subjects:
- kind: ServiceAccount
  name: $SA_NAME
  namespace: $NAMESPACE
roleRef:
  kind: $ROLE_TYPE
  name: $ROLE_NAME
  apiGroup: rbac.authorization.k8s.io
EOF

# --- Apply YAML ---
echo "Applying $ROLE_FILE..."
kubectl apply -f $ROLE_FILE

echo -e "\n✅ Done! Created $ROLE_TYPE '$ROLE_NAME' with verbs [${VERBS[*]}] on resources [$RESOURCES] and bound to ServiceAccount '$SA_NAME'."





############################################################

after creating this just create service account in given namespace and check how its working by single command from admin context

****Just run below script in your terminal

for verb in get list watch create update patch delete; do
  for resource in pods deployments secrets; do
    echo -n "$verb $resource: "
    kubectl auth can-i $verb $resource --as=system:serviceaccount:kube-system:samip -n kube-system
  done
done

