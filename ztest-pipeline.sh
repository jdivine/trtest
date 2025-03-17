#!/bin/bash

# Assumptions:
# - You have a working Azure Container Registry and AKS cluster with an ingress controller
# - You have working installs of Azure CLI, kubectl, Helm, Python, Poetry, and Podman
# - You have a .env file with the following variables set:
#   - REG_PASS: the password for the Azure Container Registry
#   - AZ_SECRET: the secret for the Azure service principal

APP=legal-term-api
VER=latest
REG=trtestreg.azurecr.io
AZ_TENANT=ec44ec06-9344-4a84-b3fe-8f38e070305e
AZ_SUB=ed407654-54f5-428f-8e6d-d7d484c844fe
AZ_RG=trtest
AZ_CLUSTER=trtestaks

REG_USER=$REG_USER
REG_PASS=$REG_PASS # load from .env file
AZ_ID=$AZ_ID # trtest-aks-admin
AZ_SECRET=$AZ_SECRET # load from .env file

# system dependencies
# sudo apt install python3-pip
# sudo apt install pipx
# pipx install poetry
export PATH=$PATH:~/.local/bin

# python dependencies
poetry sync --no-root

# run the tests
#poetry run python src/api.py 
poetry run python -m pytest

# build the container
# TODO: version this
podman build --tag $REG/$APP:$VER .

# publish the container
# az login
podman login -u ${REG_USER} -p ${REG_PASS} ${REG}
podman push ${REG}/$APP:$VER

# authenticate to the Azure Kubernetes Service cluster
az login --service-principal -u $AZ_ID -p $AZ_SECRET --tenant $AZ_TENANT
az account set --subscription $AZ_SUB
az aks get-credentials --resource-group $AZ_RG --name $AZ_CLUSTER --overwrite-existing
kubectl config use-context trtest-cluster

# ASSUMPTION: the ingress controller is already installed
# if not, use something like this:
# helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx && \
# helm repo update && \
# helm install ingress-nginx ingress-nginx/ingress-nginx \
#   ingress-nginx/ingress-nginx --create-namespace --namespace ingress-nginx \
#   --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
#   --set controller.service.externalTrafficPolicy=Local

# create a namespace for the app if it doesn't already exist
kubectl get namespace ${APP} || kubectl create namespace ${APP}

# Deploy the application using kubectl and wait for it to be available
kubectl apply -f k8s/api-deployment.yaml -n ${APP}
kubectl wait --for=condition=available --timeout=60s deployment/${APP} -n ${APP}

# Deploy the service
kubectl apply -f k8s/api-service.yaml -n ${APP}

# Deploy the ingress class and ingress
kubectl apply -f k8s/api-ingressclass.yaml -n ${APP}
kubectl apply -f k8s/api-ingress.yaml -n ${APP}

# Deploy the autoscaler
kubectl apply -f k8s/api-hpa.yaml -n ${APP}
