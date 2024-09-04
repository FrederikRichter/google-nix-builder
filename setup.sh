#!/bin/bash

# BUILD PROCESS
echo "removing Dockerfile from .gitignore"
sed -i '/^Dockerfile$/d' .gitignore
echo "generating Dockerfile from template"
cp Dockerfile_template Dockerfile
git add Dockerfile
echo "init gcloud"
gcloud init
echo "retrieving project id"
gcloud config get-value project
echo "getting region"
read -p "Enter region: " region
echo "generating ssh keys"
ssh-keygen -t rsa -f ./cloudbuild_ssh -C "$USER" -N ''
echo "copying ssh public key to Dockerfile"
sed -i "s|SSH_KEY_PLACEHOLDER|$(cat ./cloudbuild_ssh.pub | sed 's|[/&]|\\&|g')|g" Dockerfile
echo "building dockerfile on google build"
gcloud builds submit --region="$region" --config cloudbuild.yaml .
echo "deleting Dockerfile"
rm Dockerfile
echo "appending Dockerfile to .gitignore"
echo "Dockerfile" >> .gitignore

# RUN PROCESS
echo "creating buckets"
gcloud storage buckets create gs://nix-remote-build-cache --location="$region"
echo "running container"
gcloud run deploy nix-remote-build-container \
  --image 'gcr.io/nix-remote-build/nix-remote-builder:latest' \
  --region $region \
  --execution-environment=gen2 \
  --add-volume=name=build_cache,type=cloud-storage,bucket=nix-remote-build-cache \
  --add-volume-mount=volume=build_cache,mount-path=/mnt/build-cache/
