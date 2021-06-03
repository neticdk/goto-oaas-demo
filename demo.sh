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
  echo Making application namespace for devops team and removing app deployment
  kubectl --kubeconfig terraform/azure-aks/kube_config.yaml delete -k manifests/app/observable
  cp manifests/cluster/sync_full.yaml gotk/clusters/azure-aks/bootstrap/sync.yaml
  commit_and_push "Configure demo cluster with application namespace"
}

function deploy_basic() {
  kubectl --kubeconfig terraform/azure-aks/kube_config.yaml apply -k manifests/app/basic
  kubectl --kubeconfig terraform/azure-aks/kube_config.yaml apply -k manifests/app/otel
}

function deploy_observable() {
  kubectl --kubeconfig terraform/azure-aks/kube_config.yaml apply -k manifests/app/observable
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
    app_basic)
    shift
    deploy_basic
    ;;
    app_observable)
    shift
    deploy_observable
    ;;
    *)
    echo Unknown argument: $key
    shift
    ;;
  esac
done
