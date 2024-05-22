#!/usr/bin/env bash
source bash-functions.sh  # from orb-pipeline-events/bash-functions
set -eo pipefail

cluster_name=$1

export AWS_ACCOUNT_ID=$(jq -er .aws_account_id "$cluster_name".auto.tfvars.json)
export AWS_ASSUME_ROLE=$(jq -er .aws_assume_role "$cluster_name".auto.tfvars.json)
export AWS_REGION=$(jq -er .aws_region "$cluster_name".auto.tfvars.json)

awsAssumeRole "$AWS_ACCOUNT_ID" "$AWS_ASSUME_ROLE"

# aws integration smoke test
rspec test/*.rb

# cluster addons smoke test
bats test/*.bats
