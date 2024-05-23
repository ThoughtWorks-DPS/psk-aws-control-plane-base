#!/usr/bin/env bash
source bash-functions.sh  # from orb-pipeline-events/bash-functions
set -eo pipefail

cluster_name=sbx-i01-aws-us-east-1

export AWS_ACCOUNT_ID=$(jq -er .aws_account_id "$cluster_name".auto.tfvars.json)
export AWS_ASSUME_ROLE=$(jq -er .aws_assume_role "$cluster_name".auto.tfvars.json)
export AWS_REGION=$(jq -er .aws_region "$cluster_name".auto.tfvars.json)

awsAssumeRole "$AWS_ACCOUNT_ID" "$AWS_ASSUME_ROLE"

aws eks update-kubeconfig --name sbx-i01-aws-us-east-1 \
--region "us-east-1" \
--role-arn "arn:aws:iam::090950721693:role/PSKRoles/PSKControlPlaneBaseRole" \
--kubeconfig kubeconfig