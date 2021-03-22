#!/bin/bash

echo "Starting assisted-installer onprem"

podman pod create --name assisted-installer -p 5432:5432,8000:8000,8090:8090,8080:8080
podman run -dt --pod assisted-installer --env-file /etc/assisted-service/onprem-environment --name db quay.io/ocpmetal/postgresql-12-centos7
podman run -dt --pod assisted-installer --env-file /etc/assisted-service/onprem-environment -v /etc/assisted-service/nginx.conf:/opt/bitnami/nginx/conf/server_blocks/nginx.conf:z --name ui quay.io/ocpmetal/ocp-metal-ui:latest
podman run -dt --pod assisted-installer --env-file /etc/assisted-service/onprem-environment --env DUMMY_IGNITION=False \
 -v ./livecd.iso:/data/livecd.iso:z -v $(which coreos-installer):/data/coreos-installer:z --restart always \
 --name installer quay.io/ocpmetal/assisted-service@sha256:f6360493e786a7a75e92835b85ca2c8c85024395c514fb22ac9cd7ca033c001e