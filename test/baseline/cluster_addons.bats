#!/usr/bin/env bats

@test "evaluate kubeproxy" {
  run bash -c "kubectl get po -n kube-system -o wide | grep 'kube-proxy'"
  [[ "${output}" =~ "Running" ]]
}

@test "evaluate ebi csi deployment" {
  run bash -c "kubectl get po -n kube-system -o wide | grep 'ebs-csi-node'"
  [[ "${output}" =~ "Running" ]]
}

@test "evaluate aws-node" {
  run bash -c "kubectl get po -n kube-system -o wide | grep 'aws-node'"
  [[ "${output}" =~ "Running" ]]
}

@test "evaluate core-dns" {
  run bash -c "kubectl get po -n kube-system -o wide | grep 'coredns'"
  [[ "${output}" =~ "Running" ]]
}
