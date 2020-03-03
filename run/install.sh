#!/usr/bin/env bash

####### credentials #######
FILE=.env.local
if [[ ! -f "$FILE" ]]; then
    echo "$FILE does not exist. Copy .env to .env.local and fill in credentials"
    exit
fi
source .env.local
export TF_VAR_azure_client_id TF_VAR_azure_client_secret CONFLUENT_CLOUD_USERNAME CONFLUENT_CLOUD_PASSWORD


####### terraform plugins #######
# install plugins...


####### terraform #######
cd infrastructure/terraform
terraform init
terraform apply -auto-approve
#terraform refresh


mkdir -p ../../auth
echo "MONGODB_CONNECTION_STRING=$(terraform output azure-cosmos_db-connection_string_one)" > ../../auth/mongodb.env
echo "KAFKA_BOOTSTRAP_SERVERS=$(terraform output ccloud-kafka-cluster_kafka_url)" > ../../auth/kafka.env
echo "KAFKA_SASL_USERNAME=$(terraform output ccloud-kafka-cluster_key)" >> ../../auth/kafka.env
echo "KAFKA_SASL_PASSWORD=$(terraform output ccloud-kafka-cluster_secret)" >> ../../auth/kafka.env
terraform output azure-k8s-cluster_kube_config > ../../auth/kube_config
AZURE_REGISTRY=$(terraform output azure-container-registry-login_server)
DOCKER_LOGIN_COMMAND=$(terraform output azure-container-registry-docker_login)
KUBERNETES_SECRET_CREATE_COMMAND=$(terraform output azure-container-registry-kubernetes_secret)
echo ${DOCKER_LOGIN_COMMAND}
echo ${KUBERNETES_SECRET_CREATE_COMMAND}

####### build & push containers #######
cd ../../

eval ${DOCKER_LOGIN_COMMAND}

docker build -t ${AZURE_REGISTRY}/operation_service ./services/operation
docker push ${AZURE_REGISTRY}/operation_service

docker build -t ${AZURE_REGISTRY}/user_service ./services/user
docker push ${AZURE_REGISTRY}/user_service

docker build -t ${AZURE_REGISTRY}/user_approval_service ./services/userApproval
docker push ${AZURE_REGISTRY}/user_approval_service


####### k8s #######
export KUBECONFIG=$(PWD)/auth/kube_config
kubectl get node

kubectl create secret generic kafka --from-env-file=./auth/kafka.env --dry-run -o yaml | kubectl apply -f -
kubectl create secret generic mongodb --from-env-file=./auth/mongodb.env  --dry-run -o yaml | kubectl apply -f -
eval "${KUBERNETES_SECRET_CREATE_COMMAND} --dry-run -o yaml" | kubectl apply -f -
kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "docker-rep-pull"}]}'

kubectl apply -f infrastructure/k8s


####### helm #######
#kubectl create ns prometheus-adapter
cd infrastructure/helm
#helmfile sync
helmfile --helm-binary "/usr/local/opt/helm@3/bin/helm" sync
cd ../..


####### output connection info #######
echo
echo
echo "##### SETUP DONE #####"
echo "export KUBECONFIG=$(pwd)/auth/kube_config"
export KUBECONFIG=$(pwd)/auth/kube_config

ISTIO_INGRESS_IP=$(kubectl -n istio-system get svc istio-ingressgateway -o jsonpath={".status.loadBalancer.ingress[0].ip"})

if [[ -z "$ISTIO_INGRESS_IP" ]]
then
    echo
    echo "Run the following to check for the Istio LoadBalancer IP:"
    echo 'kubectl -n istio-system get svc istio-ingressgateway -o jsonpath={".status.loadBalancer.ingress[0].ip"}'
    echo
    echo "Run the following to create a new operation to create a new user:"
    echo "curl --resolve 'operation-service.scalable-microservice:80:ISTIO_INGRESS_IP' http://operation-service.scalable-microservice/operation/create/user-create -X POST -H 'Content-Type: application/json' -d '{\"name\": \"hans\"}'"
    echo
    echo "Run the following to get an operation status:"
    echo "curl --resolve 'operation-service.scalable-microservice:80:ISTIO_INGRESS_IP' http://operation-service.scalable-microservice/operation/get/f591a1e4-fb9e-459b-baa2-19ccd82fc84f"
    echo
else
    echo
    echo "Run the following to create a new operation to create a new user:"
    echo "curl --resolve 'operation-service.scalable-microservice:80:${ISTIO_INGRESS_IP}' http://operation-service.scalable-microservice/operation/create/user-create -X POST -H 'Content-Type: application/json' -d '{\"name\": \"hans\"}'"
    echo
    echo "Run the following to get an operation status:"
    echo "curl --resolve 'operation-service.scalable-microservice:80:${ISTIO_INGRESS_IP}' http://operation-service.scalable-microservice/operation/get/f591a1e4-fb9e-459b-baa2-19ccd82fc84f"
    echo
fi
