#!/usr/bin/env bats

@test "validate psk system namespace" {
  run bash -c "kubectl get ns"
  [[ "${output}" =~ "psk-system" ]]
}

@test "validate psk-adkmin clusterrolebinding" {
  run bash -c "kubectl get clusterrolebindings"
  [[ "${output}" =~ "psk-admin-clusterrolebinding" ]]
}
