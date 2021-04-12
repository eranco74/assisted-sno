#!/bin/bash
# Unsure this is still required
install -d -m 0777  /etc/assisted-service/postgress-data/

echo "Wait for node IP"
hostname -I | cut -d' ' -f1
until [ $(hostname -I | cut -d' ' -f1) ]; 
do
  echo "Waiting for node IP";
  sleep 2; 
done
echo "Update onprem-environment file with node IP"
sed -i "s/<NODE_IP>/$(hostname -I | cut -d' ' -f1)/" /etc/assisted-service/onprem-environment
echo "Starting assisted-installer onprem"
podman  pod rm assisted-installer-onprem -f | true
podman pod create --name assisted-installer-onprem -p 5432:5432,8000:8000,8090:8090,8080:8080
podman run -dt --pod assisted-installer-onprem -v /etc/assisted-service/postgress-data:/opt/app-root/src:rw,z --env-file /etc/assisted-service/onprem-environment --name db quay.io/ocpmetal/postgresql-12-centos7
podman run -dt --pod assisted-installer-onprem --env-file /etc/assisted-service/onprem-environment -v /etc/assisted-service/nginx.conf:/opt/bitnami/nginx/conf/server_blocks/nginx.conf:z --name ui quay.io/ocpmetal/ocp-metal-ui:latest
echo "Wait for the DB to start..."
sleep 15
if [ -f /etc/assisted-service/postgress-data/installer.sql ]; then
  echo "Restoring postgress data"
  podman exec -it db bash -c "psql installer <  /opt/app-root/src/installer.sql"
  echo "Update host status and stage"
  podman exec -it db /usr/bin/psql -d installer -c "UPDATE hosts SET status='installing-in-progress', progress_current_stage='Configuring' WHERE id is not null;"
fi

podman run --pod assisted-installer-onprem --env-file /etc/assisted-service/onprem-environment --env DUMMY_IGNITION=False \
 -v /etc/assisted-service/assisted-data:/data:z -v /bin/coreos-installer:/data/coreos-installer:z --restart always \
 --name installer quay.io/eranco74/bm-inventory:onprem

