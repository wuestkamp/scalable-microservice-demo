#!/usr/bin/env bash

####### credentials #######
FILE=.env.local
if [ ! -f "$FILE" ]; then
    echo "$FILE does not exist. Copy .env to .env.local and fill in credentials"
    exit
fi
source .env.local
export TF_VAR_azure_client_id TF_VAR_azure_client_secret CONFLUENT_CLOUD_USERNAME CONFLUENT_CLOUD_PASSWORD


####### terraform #######
cd infrastructure/terraform
terraform destroy -auto-approve

rm -rf auth/*
