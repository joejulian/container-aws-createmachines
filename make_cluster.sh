#!/bin/bash

if [ -z "${CLUSTER_ID}" ]; then
    echo "CLUSTER_ID must be set"
    exit 1
fi

if [ -z "${AVAILABILITY_ZONE}" ]; then
    echo "AVAILABILIT_ZONE must be set"
    exit 1
fi

CLUSTER_USERNAME=${CLUSTER_USERNAME:-ubuntu}
INSTANCE_TYPE=${INSTANCE_TYPE:-m4.large}
DISK_SIZE_GB=${DISK_SIZE_GB:-40}
SSH_LOCATION=${SSH_LOCATION:-0.0.0.0/0}
K8S_NODE_CAPACITY=${K8S_NODE_CAPACITY:-1}

KEYFILE=$(mktemp)
aws ec2 create-key-pair --key-name "${CLUSTER_ID}Key" --query 'KeyMaterial' --output text >> ${KEYFILE}

PARAMETER_OVERRIDES="CmsId=${CLUSTER_ID}"
PARAMETER_OVERRIDES="${PARAMETER_OVERRIDES} KeyName=${CLUSTER_ID}Key"
PARAMETER_OVERRIDES="${PARAMETER_OVERRIDES} username=${CLUSTER_USERNAME}"
PARAMETER_OVERRIDES="${PARAMETER_OVERRIDES} InstanceType=${INSTANCE_TYPE}"
PARAMETER_OVERRIDES="${PARAMETER_OVERRIDES} DiskSizeGb=${DISK_SIZE_GB}"
PARAMETER_OVERRIDES="${PARAMETER_OVERRIDES} AvailabilityZone=${AVAILABILITY_ZONE}"
PARAMETER_OVERRIDES="${PARAMETER_OVERRIDES} SSHLocation=${SSH_LOCATION}"
PARAMETER_OVERRIDES="${PARAMETER_OVERRIDES} K8sNodeCapacity=${K8S_NODE_CAPACITY}"

CREATED=$(mktemp)
aws cloudformation deploy --stack-name=${CLUSTER_ID} --template-file=cluster.cf.template --capabilities CAPABILITY_IAM \
    --parameter-overrides \
    CmsId="${CLUSTER_ID}" \
    KeyName="${CLUSTER_ID}Key" \
    username="${CLUSTER_USERNAME}" \
    InstanceType="${INSTANCE_TYPE}" \
    DiskSizeGb="${DISK_SIZE_GB}" \
    AvailabilityZone="${AVAILABILITY_ZONE}" \
    SSHLocation="${SSH_LOCATION}" \
    K8sNodeCapacity="${K8S_NODE_CAPACITY}" | tee ${CREATED}


S_TIME=2
WORKERS=$(aws ec2 describe-instances --filters "Name=tag:cms_id,Values=${CLUSTER_ID}" "Name=tag:role,Values=worker" --query 'Reservations[].Instances[].PublicIpAddress')
while [ $(jq ". | length" <<< "${WORKERS}") -lt ${K8S_NODE_CAPACITY} ]; do
    sleep ${S_TIME}
    S_TIME=$(( $S_TIME * $S_TIME ))
    WORKERS=$(aws ec2 describe-instances --filters "Name=tag:cms_id,Values=${CLUSTER_ID}" "Name=tag:role,Values=worker" --query 'Reservations[].Instances[].PublicIpAddress')
done

export CMS_ID=${CLUSTER_ID} SSH_USER=${CLUSTER_USERNAME}

if [ -z "${KUBERNETES_SERVICE_HOST}" ]; then
    . ./configure
    echo
    cat ${KEYFILE}
else
    . ./configure | kubectl apply -f -
    kubectl create secret generic ${CLUSTER_ID}PrivateKey --from-file=${KEYFILE}
fi
