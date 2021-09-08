#!/usr/bin/env bash

# Script to execute different demo steps
script_dir=$(dirname $0)
pushd $script_dir

function commit_and_push() {
  git add gotk/clusters/$1/bootstrap/sync.yaml
  git commit -m "chore: $2"
  git push
}

function cleanup() {
  echo Resetting cluster
  cp manifests/cluster/$1/sync_basic.yaml gotk/clusters/$1/bootstrap/sync.yaml
  commit_and_push $1 "Reset demo cluster configuration"
}

function observable() {
  echo Making cluster observable
  cp manifests/cluster/$1/sync_observable.yaml gotk/clusters/$1/bootstrap/sync.yaml
  commit_and_push $1 "Configure demo cluster for observability"
}

function namespace() {
  echo Making application namespace for devops team and removing app deployment
  kubectl --kubeconfig terraform/$1/kube_config.yaml delete -k manifests/app/observable
  cp manifests/cluster/$1/sync_full.yaml gotk/clusters/$1/bootstrap/sync.yaml
  commit_and_push $1 "Configure demo cluster with application namespace"
}

function deploy_basic() {
  echo Deploying hotrod without observability
  kubectl --kubeconfig terraform/$1/kube_config.yaml apply -k manifests/app/basic
}

function deploy_observable() {
  echo Deploying hotrod with observability
  kubectl --kubeconfig terraform/$1/kube_config.yaml apply -k manifests/app/otel
  kubectl --kubeconfig terraform/$1/kube_config.yaml label ns default netic.dk/monitoring="true"
  sleep 5
  kubectl --kubeconfig terraform/$1/kube_config.yaml apply -k manifests/app/observable
}

function remove_app() {
  echo Removing hotrod deployment
  kubectl --kubeconfig terraform/$1/kube_config.yaml delete -k manifests/app/observable
}

key="$1"

case $key in
  cleanup)
  shift
  cleanup $1
  ;;
  observable)
  shift
  observable $1
  ;;
  namespace)
  shift
  namespace $1
  ;;
  app_basic)
  shift
  deploy_basic $1
  ;;
  app_observable)
  shift
  deploy_observable $1
  ;;
  app_remove)
  shift
  remove_app $1
  ;;
  *)
  echo Unknown argument: $key
  shift
  ;;
esac

popd
