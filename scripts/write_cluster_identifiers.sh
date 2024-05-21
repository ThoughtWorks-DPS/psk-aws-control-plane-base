#!/usr/bin/env bash
source bash_functions.sh
set -eo pipefail

cluster_name=$1

export AWS_ACCOUNT_ID=$(jq -er .aws_account_id "$cluster_name".auto.tfvars.json)
export AWS_ASSUME_ROLE=$(jq -er .aws_assume_role "$cluster_name".auto.tfvars.json)
export AWS_REGION=$(jq -er .aws_region "$cluster_name".auto.tfvars.json)

awsAssumeRole "$AWS_ACCOUNT_ID" "$AWS_ASSUME_ROLE"

update kubeconfig based on assume-role
aws eks update-kubeconfig --name "$cluster_name" \
--region "$AWS_REGION" \
--role-arn arn:aws:iam::"$AWS_ACCOUNT_ID":role/"$AWS_ASSUME_ROLE" --alias "$cluster_name" \
--kubeconfig "~/.kube/config"

write1passwordField empc-lab $cluster_name kubeconfig-base64 $(cat ~/.kube/config | base64)
write1passwordField empc-lab $cluster_name cluster-url $(terraform output -raw cluster_url)
write1passwordField empc-lab $cluster_name base64-certificate-authority-data $(terraform output -raw cluster_public_certificate_authority_data)
