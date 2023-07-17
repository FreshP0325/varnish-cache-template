#!/bin/bash
test -z "${DEBUG}" || set -o xtrace
set -o errexit

cd "$(dirname "$0")"

cert=/etc/ssl/certs/ca-certificates.crt

main() {
  setCluster

  envsubst '$IMAGE_NAME' < ../k8s/base/egress/deployment-template.yaml > ../k8s/base/egress/deployment.yaml
  kubectl apply -k ../k8s/base
  
  kubectl rollout restart deployment egress-router
}

setCluster() {
  # Configure kubectl to talk to Section
  
  # change the cert path depending on OS.
  if [[ "$OSTYPE" == "darwin"* ]]; then
    cert=/usr/local/etc/ca-certificates/cert.pem
  fi

  kubectl config set-cluster section-varnish \
  --server=$SECTION_K8S_API_URL \
  --certificate-authority=$cert

  kubectl config set-credentials section-user --token=$SECTION_API_TOKEN

  kubectl config set-context my-varnish-app --cluster=section-varnish --user=section-user --namespace=default

  kubectl config use-context my-varnish-app

  kubectl version
}

"$@"
