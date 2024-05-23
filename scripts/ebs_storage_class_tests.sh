#!/usr/bin/env bash
source bash-functions.sh  # from orb-pipeline-events/bash-functions
set -eo pipefail

cluster_name=$1
export AWS_REGION=$(jq -er .aws_region "$cluster_name".auto.tfvars.json)

# create test ebs storage class
kubectl apply -f test/ebs/test-ebs-storage-class.yaml

# test creation ebs-csi dynamic volume
kubectl apply -f test/ebs/dynamic-volume/initial-volume-claim.yaml
kubectl apply -f test/ebs/dynamic-volume/dynamic-volume-test-pod.yaml
sleep 5
bats test/ebs/dynamic-volume/initial-pvc-test.bats

# test expanding dynamic volume size
kubectl apply -f test/ebs/dynamic-volume/expand-volume-claim.yaml
sleep 10
bats test/ebs/dynamic-volume/expanded-pvc-test.bats

kubectl delete -f test/ebs/dynamic-volume/dynamic-volume-test-pod.yaml
kubectl delete -f test/ebs/dynamic-volume/expand-volume-claim.yaml

# test create ebs-csi block volume
kubectl apply -f test/ebs/block-volume/block-volume-claim-test.yaml
sleep 15
bats test/ebs/block-volume/block-volume-claim-test.bats

kubectl delete -f test/ebs/block-volume/block-volume-claim-test.yaml
kubectl delete -f test/ebs/test-ebs-storage-class.yaml

