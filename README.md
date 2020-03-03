# Scalable Microservice Infrastructure Example with K8s Istio Kafka

Medium article: TODO

## Setup project
Install:
* terraform
* https://github.com/Mongey/terraform-provider-confluent-cloud
* kubectl
* docker
* helmfile

Then:
```
cp .env .env.local
# fill .env.local with correct values

./run/install.sh
```

## Run
Edit `infrastructure/k8s/rest-request.yaml` deployment to fetch the correct Istio Gateway IP. Then slowly
raise its replicas and watch the metrics.



## Monitor Cluster

### Grafana
Run Grafana and then import the `./infrastructure/grafana/dashboard.json`.

```
./run/grafana.sh # admin:admin
```

### Kiali
```
./run/kiali.sh # admin:admin
```



## Use/build Services manually

### build and run
```
cd services/operator

# pass env file
docker build -t operation-service . && \
    docker run --env-file ../../auth/kafka.env \
    --env-file ../../auth/mongodb.env \
    -p 80:5000 \
    operation-service


# build and pass all parameters manually
docker build -t operation-service . && \
    docker run -e "KAFKA_BOOTSTRAP_SERVERS=server:9092" \
    -e "KAFKA_SASL_USERNAME=XXX" \
    -e "KAFKA_SASL_PASSWORD=XXX" \
    -e "MONGODB_CONNECTION_STRING=mongodb://" \
    -p 80:5000 \
    operation-service
```

### call and use
```
# add user
curl -X POST \
    -H 'Content-Type: application/json' \
    -d '{"name": "hans"}' \
    "http://localhost:80/operation/create/user-create"

curl -X POST -H 'Content-Type: application/json' -d '{"name": "hans"}' "http://localhost:80/operation/create/user-create"

# get operation status
curl "http://localhost:80/operation/get/6d232092-dceb-419f-bff1-2d686eace56c"
```


## User Service

### build and run
```
cd services/user

docker build -t user-service . && \
    docker run --env-file ../../auth/kafka.env \
    --env-file ../../auth/mongodb.env \
    user-service

# build and pass all env variables manually
docker build -t user-service . && \
    docker run -e "KAFKA_BOOTSTRAP_SERVERS=server:9092" \
    -e "KAFKA_SASL_USERNAME=XXX" \
    -e "KAFKA_SASL_PASSWORD=XXX" \
    -e "MONGODB_CONNECTION_STRING=mongodb://" \
    user-service
```


## User Approval Service

### build and run
```
docker build -t user-approval-service . && \
    docker run --env-file ../../auth/kafka.env \
    user-approval-service
```




## Setup project step by step

### Terraform
https://docs.microsoft.com/en-us/azure/terraform/terraform-create-k8s-cluster-with-tf-and-aks

#### Plugins

install Terraform ConfluenceCloud plugin
```
TF_PLUGIN_VERSION=0.0.1
mkdir ~/.terraform.d/plugins/darwin_amd64
cd ~/tmp
wget "https://github.com/Mongey/terraform-provider-confluent-cloud/releases/download/v${TF_PLUGIN_VERSION}/terraform-provider-confluent-cloud_${TF_PLUGIN_VERSION}_darwin_amd64.tar.gz"
tar xzf terraform-provider-confluent-cloud_${TF_PLUGIN_VERSION}_darwin_amd64.tar.gz
mv terraform-provider-confluent-cloud_v${TF_PLUGIN_VERSION} ~/.terraform.d/plugins/darwin_amd64/
```

#### Init
```
terraform init
```

#### Plan & Apply
```
cp .env .env.local
# fill .env.local with correct values

source .env.local
export TF_VAR_azure_client_id TF_VAR_azure_client_secret CONFLUENT_CLOUD_USERNAME CONFLUENT_CLOUD_PASSWORD

cd infrastructure/terraform
terraform apply
```

#### Connect
```
echo "$(terraform output azure-k8s-cluster_kube_config)" > ./kube_config
export KUBECONFIG=$(PWD)/kube_config
kubectl get node
```


### Istio
Istio is already persisted at `infrastructure/k8s/istio-system.yaml`. It was generated using:
```
istioctl manifest generate --set values.kiali.enabled=true --set values.tracing.enabled=true --set values.grafana.enabled=true --set values.prometheus.enabled=true
```


### Apply K8s Resources
```
kubectl apply -f infrastructure/k8s
```


### Install Helm Charts
If your k8s provider doesn't install metrics-server you need to enable in it `infrastructure/helm/helmfile.yaml`
and the namespace in `infrastructure/k8s/namespaces.yaml`.

```
cd infrastructure/helm

# as of now I had to specify the path to helm3 manually because I also had helm2 installed
helmfile --helm-binary "/usr/local/opt/helm@3/bin/helm" diff
helmfile --helm-binary "/usr/local/opt/helm@3/bin/helm" sync
```


## view Terraform credentials
```
terraform refresh
```


## Kafka commands

### Apache Kafka CLI
Use Apache Kafka CLI tools with ConfluentCloud:
https://www.confluent.io/blog/using-apache-kafka-command-line-tools-confluent-cloud

First create the file `kafka.config.properties` and add the API key and token.

```
kafka-console-producer --broker-list pkc-e8mp5.eu-west-1.aws.confluent.cloud:9092 --producer.config kafka.config.properties --topic user-create
kafka-console-consumer --bootstrap-server pkc-e8mp5.eu-west-1.aws.confluent.cloud:9092 --consumer.config kafka.config.properties --topic user-create
```



### Confluent Cloud CLI
```
ccloud api-key create --resource lkc-1j98z
ccloud api-key use XXX --resource lkc-1j98z

ccloud kafka topic create test-topic
ccloud kafka topic produce test-topic
ccloud kafka topic consume test-topic
```
