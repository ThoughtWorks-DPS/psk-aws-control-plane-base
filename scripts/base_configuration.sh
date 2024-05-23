#!/usr/bin/env bash
source bash-functions.sh  # from orb-pipeline-events/bash-functions
set -eo pipefail

cluster_name=$1

export AWS_ACCOUNT_ID=$(jq -er .aws_account_id "$cluster_name".auto.tfvars.json)
export AWS_ASSUME_ROLE=$(jq -er .aws_assume_role "$cluster_name".auto.tfvars.json)
export AWS_REGION=$(jq -er .aws_region "$cluster_name".auto.tfvars.json)

cat ~/.kube/config

kubeconfig=$(cat ~/.kube/config | base64)

# store cluster identifiers in 1password vault
write1passwordField empc-lab "psk-aws-${cluster_name}" kubeconfig-base64 kubeconfig
write1passwordField empc-lab "psk-aws-${cluster_name}" cluster-url $(terraform output -raw cluster_url)
write1passwordField empc-lab "psk-aws-${cluster_name}" base64-certificate-authority-data $(terraform output -raw cluster_public_certificate_authority_data)

# # apply baseline cluster resources
# # psk-system namespace
# kubectl apply -f tpl/psk-system-namespace.yaml
# # twdps-core-labs-team oidc admin clusterrolebinding
# kubectl apply -f tpl/psk-admin-clusterrolebinding.yaml

# aws eks update-kubeconfig --name sbx-i01-aws-us-east-1 \
# --region "us-east-1" \
# --role-arn "arn:aws:iam::090950721693:role/PSKRoles/PSKControlPlaneBaseRole" \
# --kubeconfig kubeconfig



# aws eks create-access-entry --cluster-name sbx-i01-aws-us-east-1 --principal-arn "arn:aws:iam::090950721693:role/PSKRoles/PSKControlPlaneBaseRole"

# aws eks associate-access-policy --cluster-name sbx-i01-aws-us-east-1 \
#   --principal-arn "arn:aws:iam::090950721693:role/PSKRoles/PSKControlPlaneBaseRole" \
#   --policy-arn "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy" \
#   --access-scope type=cluster



# with what has been created now:

# PSKservice account can assume role to generate kubeconfig, and then it can access cluster without an assumed role, cause sthe lubeconfig does it.