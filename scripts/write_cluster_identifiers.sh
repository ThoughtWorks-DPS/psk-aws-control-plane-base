#!/usr/bin/env bash
source bash-functions.sh
set -eo pipefail

cluster_name=$1

export AWS_ACCOUNT_ID=$(jq -er .aws_account_id "$cluster_name".auto.tfvars.json)
export AWS_ASSUME_ROLE=$(jq -er .aws_assume_role "$cluster_name".auto.tfvars.json)
export AWS_REGION=$(jq -er .aws_region "$cluster_name".auto.tfvars.json)

awsAssumeRole "$AWS_ACCOUNT_ID" "$AWS_ASSUME_ROLE"

# update kubeconfig based on assume-role
aws eks update-kubeconfig --name "$cluster_name" \
--region "$AWS_REGION" \
--role-arn arn:aws:iam::"$AWS_ACCOUNT_ID":role/"$AWS_ASSUME_ROLE" --alias "$cluster_name" \
--kubeconfig "kubeconfig"
#--kubeconfig "~/.kube/config"



# cluster_role=$1

# instance_name=$(jq -er .instance_name "$cluster_role".auto.tfvars.json)
# #export AWS_REGION=us-east-1

# cat ~/.kube/config

# # write kubeconfig to AWS secrets manager
# teller put KUBECONFIG_BASE64="$(cat ~/.kube/config | base64)" --providers aws_secretsmanager -c .teller.yml

# # # write cluster url and pubic certificate to AWS secrets manager
# teller put CLUSTER_URL="$(terraform output -raw cluster_url)" --providers aws_secretsmanager -c .teller.yml
# teller put CLUSTER_PUBLIC_CERTIFICATE_AUTHORITY_DATA="$(terraform output -raw cluster_public_certificate_authority_data)" --providers aws_secretsmanager -c .teller.yml