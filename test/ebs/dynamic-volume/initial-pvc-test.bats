#!/usr/bin/env bats

@test "validate ebs storage class created" {
  run bash -c "kubectl get storageclasses | grep 'ebs-csi-test-storage-class'"
  [[ "${output}" =~ "WaitForFirstConsumer" ]]
}

@test "validate ebs storage class created with volume expansion allowed" {
  run bash -c "kubectl get storageclasses | grep 'ebs-csi-test-storage-class'"
  [[ "${output}" =~ "true" ]]
}

@test "validate dynamic ebs volume claim created" {
  run bash -c "kubectl describe pv | grep 'psk-system/test-ebs-claim'"
  [[ "${output}" =~ "Claim" ]]
}

@test "validate claim-test-pod health" {
  run bash -c "kubectl get all -n psk-system | grep 'pod/claim-test-pod'"
  [[ "${output}" =~ "Running" ]]
}

@test "validate dynamic ebs pvc write access" {
  run bash -c "kubectl exec -it -n psk-system claim-test-pod -- cat /data/out.txt"
  [[ "${output}" =~ "UTC" ]]
}