#!/bin/bash

# change this if a bucket with this name exists
BUCKET_NAME="nix-remote-builder"

# BUILD PROCESS
echo "init gcloud"
gcloud init --skip-diagnostics

echo "retrieving project id"
PROJECT_ID=$(gcloud config get-value project)

echo "getting region"
read -p "Enter region: " region

echo "cloning build script"
rm -rf nixpkgs/
git clone --depth=1 --branch 23.11 https://github.com/NixOS/nixpkgs.git

echo "creating bucket nix-remote-builder"
if gcloud storage buckets create gs://$BUCKET_NAME; then
    BUCKET_NAME=$BUCKET_NAME nixpkgs/nixos/maintainers/scripts/gce/create-gce.sh
    echo "created bucket"
else
    echo "there is a bucket with this name already, change name in setup.sh"
    exit
fi


echo "generating ssh keys"
ssh-keygen -t rsa -f ./cloudbuild_ssh -C "$USER" -N ''

echo "building dockerfile on google build"
image="$region-docker.pkg.dev/$PROJECT_ID/nix-remote-build/nix-remote-build:latest"

# gcloud builds submit --region="$region" --tag $image .

# DEPLOY COMPUTE ENGINE
echo "Deploy Compute Engine (8c/16gb)? [Y,n]"
read input

if [[ $input == "Y" || $input == "y" ]]; then
    ssh_key_pub=$(cat cloudbuild_ssh.pub)
    service_account=$(gcloud projects describe $(gcloud config get-value project) --format='value(projectNumber)')-compute@developer.gserviceaccount.com
    gcloud beta compute instances create-with-container nix-remote-build \
        --project=$PROJECT_ID \
        --zone=$region-b \
        --machine-type=e2-custom-8-16384 \
        --network-interface=network-tier=STANDARD,stack-type=IPV4_ONLY,subnet=default \
        --maintenance-policy=MIGRATE \
        --provisioning-model=STANDARD \
        --instance-termination-action=STOP \
        --max-run-duration=7200s \
        --host-error-timeout-seconds=300 \
        --service-account=$service_account \
        --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/trace.append \
        --image=projects/cos-cloud/global/images/cos-stable-113-18244-151-27 \
        --boot-disk-size=40GB \
        --boot-disk-type=pd-ssd \
        --boot-disk-device-name=nix-remote-build \
        --container-image=$image \
        --container-restart-policy=always \
        --no-shielded-secure-boot \
        --shielded-vtpm \
        --shielded-integrity-monitoring \
        --labels=goog-ec-src=vm_add-gcloud,container-vm=cos-stable-113-18244-151-27 \
        --metadata=ssh-keys=$(whoami):"$ssh_key_pub"
    
        echo "testing ssh connection"
        ip=$(gcloud compute instances describe nix-remote-build --format='get(networkInterfaces[0].networkIP)')

else
    echo "exiting"
fi
