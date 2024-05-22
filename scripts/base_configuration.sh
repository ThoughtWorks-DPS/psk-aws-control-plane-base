#!/usr/bin/env bash
source bash-functions.sh  # from orb-pipeline-events/bash-functions
set -eo pipefail

cluster_name=$1

export AWS_ACCOUNT_ID=$(jq -er .aws_account_id "$cluster_name".auto.tfvars.json)
export AWS_ASSUME_ROLE=$(jq -er .aws_assume_role "$cluster_name".auto.tfvars.json)
export AWS_REGION=$(jq -er .aws_region "$cluster_name".auto.tfvars.json)

awsAssumeRole "$AWS_ACCOUNT_ID" "$AWS_ASSUME_ROLE"

# generate kubeconfig based on PSK service account role
aws eks update-kubeconfig --name "$cluster_name" \
--region "$AWS_REGION" \
--role-arn "arn:aws:iam::$AWS_ACCOUNT_ID:role/$AWS_ASSUME_ROLE --alias $cluster_name" \
--kubeconfig "~/.kube/config"

# store cluster identifiers in 1password vault
write1passwordField empc-lab "psk-aws-${cluster_name}" kubeconfig-base64 $(cat ~/.kube/config | base64)
write1passwordField empc-lab "psk-aws-${cluster_name}" cluster-url $(terraform output -raw cluster_url)
write1passwordField empc-lab "psk-aws-${cluster_name}" base64-certificate-authority-data $(terraform output -raw cluster_public_certificate_authority_data)

# apply baseline cluster resources
# psk-system namespace
kubectl apply -f tpl/psk-system-namespace.yaml
# twdps-core-labs-team oidc admin clusterrolebinding
kubectl apply -f tpl/psk-admin-clusterrolebinding.yaml
