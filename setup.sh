#!/bin/bash

# BUILD PROCESS
echo "init gcloud"
gcloud init

echo "retrieving project id"
project_id=$(gcloud config get-value project)

echo "getting region"
read -p "Enter region: " region

echo "checking artifacts repo"
if gcloud artifacts repositories describe nix-remote-build --location=$region; then
    echo "using existing nix-remote-build repo"
else
    echo "creating artifacts repo"
    gcloud artifacts repositories create nix-remote-build --repository-format=docker \
        --location=$region --description="nix-remote-build artifacts repo"
fi

echo "generating ssh keys"
ssh-keygen -t rsa -f ./cloudbuild_ssh -C "$USER" -N ''

echo "building dockerfile on google build"
image="$region-docker.pkg.dev/$project_id/nix-remote-build/nix-remote-build:latest"

gcloud builds submit --region="$region" --tag $image .

# DEPLOY COMPUTE ENGINE
echo "Deploy Compute Engine (8c/16gb)? [Y,n]"
read input

if [[ $input == "Y" || $input == "y" ]]; then
ssh_key_pub=$(cat cloudbuild_ssh.pub)
        gcloud beta compute instances create-with-container nix-remote-builder \
  --project=$project_id \
  --zone=$region-b \
  --machine-type=e2-custom-8-16384 \
  --network-interface=network-tier=STANDARD,stack-type=IPV4_ONLY,subnet=default \
  --maintenance-policy=MIGRATE \
  --provisioning-model=STANDARD \
  --instance-termination-action=STOP \
  --max-run-duration=7200s \
  --host-error-timeout-seconds=300 \
  --no-service-account \
  --no-scopes \
  --image=projects/cos-cloud/global/images/cos-stable-113-18244-151-27 \
  --boot-disk-size=40GB \
  --boot-disk-type=pd-ssd \
  --boot-disk-device-name=nix-remote-builder \
  --container-image=$image \
  --container-restart-policy=always \
  --no-shielded-secure-boot \
  --shielded-vtpm \
  --shielded-integrity-monitoring \
  --labels=goog-ec-src=vm_add-gcloud,container-vm=cos-stable-113-18244-151-27 \
  --metadata=ssh-keys=$ssh_key_pub
else
    echo "exiting"
fi
