#!/usr/bin/env bats

@test "validate ebs volume expansion" {
  run bash -c "kubectl get pvc test-ebs-claim -n psk-system | grep '8Gi'"
  [[ "${output}" =~ "Bound" ]]
}
