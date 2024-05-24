#!/usr/bin/env bats

@test "validate efs dynamic volume claim" {
  run bash -c "kubectl exec efs-app -n psk-system -- bash -c 'tail -n 5 data/out'"
  [[ "${output}" =~ "UTC" ]]
}
