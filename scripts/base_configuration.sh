#!/usr/bin/env bash
source bash-functions.sh  # from orb-pipeline-events/bash-functions
set -eo pipefail

cluster_name=$1
export AWS_REGION=$(jq -er .aws_region "$cluster_name".auto.tfvars.json)
kubeconfig=$(cat ~/.kube/config | base64)

# store cluster identifiers in 1password vault
write1passwordField empc-lab "psk-aws-${cluster_name}" kubeconfig-base64 "$kubeconfig"
write1passwordField empc-lab "psk-aws-${cluster_name}" cluster-url $(terraform output -raw cluster_url)
write1passwordField empc-lab "psk-aws-${cluster_name}" base64-certificate-authority-data $(terraform output -raw cluster_public_certificate_authority_data)
write1passwordField empc-lab "psk-aws-${cluster_name}" eks_efs_csi_storage_id $(terraform output -raw eks_efs_csi_storage_id)
eks_efs_csi_storage_id=$(terraform output -raw eks_efs_csi_storage_id)

# apply baseline cluster resources ================================

# create psk-system namespace
kubectl apply -f tpl/psk-system-namespace.yaml

# create twdps-core-labs-team oidc admin clusterrolebinding
kubectl apply -f tpl/psk-admin-clusterrolebinding.yaml

# create cluster ebs-csi storage class
cat <<EOF > tpl/ebs-csi-storage-class.yaml
---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: ${cluster_name}-ebs-csi-dynamic-storage
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
parameters:
  csi.storage.k8s.io/fstype: xfs
  type: io1
  iopsPerGB: "50"
  encrypted: "true"
EOF
kubectl apply -f tpl/ebs-csi-storage-class.yaml

# create cluster efs-csi storage class
cat <<EOF > tpl/efs-csi-storage-class.yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: ${cluster_name}-efs-csi-dynamic-storage
provisioner: efs.csi.aws.com
parameters:
  provisioningMode: efs-ap
  fileSystemId: $eks_efs_csi_storage_id
  directoryPerms: "700"
  basePath: "/dynamic_storage"
  subPathPattern: \${.PVC.namespace}/\${.PVC.name}
  ensureUniqueDirectory: "true"
  reuseAccessPoint: "false"
EOF
kubectl apply -f tpl/efs-csi-storage-class.yaml
