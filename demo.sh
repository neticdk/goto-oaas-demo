#!/usr/bin/env bash

# Script to execute different demo steps

function commit_and_push() {
  git add gotk/clusters/azure-aks/bootstrap/sync.yaml
  git commit -m "chore: $1"
  git push
}

function cleanup() {
  echo Resetting cluster
  cp manifests/cluster/sync_basic.yaml gotk/clusters/azure-aks/bootstrap/sync.yaml
  commit_and_push "Reset demo cluster configuration"
}

function observable() {
  echo Making cluster observable
  cp manifests/cluster/sync_observable.yaml gotk/clusters/azure-aks/bootstrap/sync.yaml
  commit_and_push "Configure demo cluster for observability"
}

function namespace() {
  echo Making application namespace for devops team
  cp manifests/cluster/sync_full.yaml gotk/clusters/azure-aks/bootstrap/sync.yaml
  commit_and_push "Configure demo cluster with application namespace"
}

while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    cleanup)
    shift
    cleanup
    ;;
    observable)
    shift
    observable
    ;;
    namespace)
    shift
    namespace
    ;;
    *)
    echo Unknown argument: $key
    shift
    ;;
  esac
done
