#!/bin/bash

echo "Starting assisted-installer onprem"
podman  pod rm assisted-installer -f | true
podman pod create --name assisted-installer -p 5432:5432,8000:8000,8090:8090,8080:8080
podman run -dt --pod assisted-installer --env-file /etc/assisted-service/onprem-environment --name db quay.io/ocpmetal/postgresql-12-centos7
podman run -dt --pod assisted-installer --env-file /etc/assisted-service/onprem-environment -v /etc/assisted-service/nginx.conf:/opt/bitnami/nginx/conf/server_blocks/nginx.conf:z --name ui quay.io/ocpmetal/ocp-metal-ui:latest
echo "Wait for the DB to start..."
sleep 15
podman run --pod assisted-installer --env-file /etc/assisted-service/onprem-environment --env DUMMY_IGNITION=False \
 -v /etc/assisted-service/fake-livecd.iso:/data/livecd.iso:z -v /bin/coreos-installer:/data/coreos-installer:z --restart always \
 --name installer quay.io/eranco74/bm-inventory:onprem