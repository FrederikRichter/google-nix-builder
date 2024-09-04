#!/bin/bash
project_id=$1
zone=$2
image=$3

gcloud compute instances create-with-container nix-remote-builder \
  --project=project_id \
  --zone=$zone-b \
  --machine-type=e2-custom-8-16384 \
  --network-interface=network-tier=STANDARD,stack-type=IPV4_ONLY,subnet=default \
  --maintenance-policy=MIGRATE \
  --provisioning-model=STANDARD \
  --instance-termination-action=STOP \
  --max-run-duration=7200s \
  --host-error-timeout-seconds=330 \
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
  --labels=goog-ec-src=vm_add-gcloud,container-vm=cos-stable-113-18244-151-27
