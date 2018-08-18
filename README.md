# aws-createmachines

This container can be run in a cluster to create aws machine resources for cluster-api.

## Usage

This container is configured through environment variables:

### Required:

- **CLUSTER_ID** This is the name of the cluster, eg "MyCluster".
- **AWS_ACCESS_KEY_ID** The aws access key id to create the cluster with.
- **AWS_SECRET_ACCESS_KEY** The aws secret associated with the above key.
- **AWS_DEFAULT_REGION** The aws region in which to build this cluster.
- **AVAILABILITY_ZONE** A single availability zone the the default region.

### Optional:
- **CLUSTER_USERNAME** A user account to add to the node. Default: ubuntu
- **INSTANCE_TYPE** The aws instance type. Default: m4.large
- **DISK_SIZE_GB** The instance disk size in gigabytes. Default: 40
- **SSH_LOCATION** The CIDR allowed to ssh in to this cluster. Default: 0.0.0.0/0
- **K8S_NODE_CAPACITY** The number of worker nodes in this cluster. Default: 1

If run in a kubernetes cluster, this container will use the service account to
attempt to create resources.
Ensure the service account is allowed to create secrets and machines.cluster.k8s.io
resources in its namespace.

## Output

This container will create in the pod's namespace:
- ***machines.cluster.k8s.io*** resources for each machine in the cluster
- a ***{CLUSTER_ID}PrivateKey*** secret
