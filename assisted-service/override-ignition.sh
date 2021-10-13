#!/usr/bin/env bash
set -euoE pipefail ## -E option will cause functions to inherit trap

until [ -f /usr/local/bin/bootstrap-in-place.sh ]; do
  echo "Waiting for bootstrap-in-place.sh"
  sleep 5
done

# echo this code to the end of the file

cat <<EOT >> /usr/local/bin/bootstrap-in-place.sh
echo "Create postgress backup"
podman exec -it db pg_dump installer >  /etc/assisted-service/postgress-data/installer.sql

# copy the original master ignition
if [ ! -f /etc/assisted-service/master.ign ];
then
    cp /opt/openshift/master.ign /etc/assisted-service/
fi

rm /etc/assisted-service/assisted-data/rhcos*

# Generate the ignition
echo "Rendering ignition"
podman run --rm -v /usr/local/bin:/data/bin -v /etc/assisted-service/:/data quay.io/coreos/fcct:release --pretty -d /data --strict /data/assisted-service.fcc > /opt/openshift/master.ign
EOT

## Get the host id:
#CLUSTER_ID=c1dca253-bb31-4e41-982a-482885d10e1a
#curl -s http://127.0.0.1:8090/api/assisted-install/v1/clusters/$CLUSTER_ID | jq ".hosts[0].id"
#
## update the ignition // add config
#
## patch the host ignition
#curl -X PATCH  -H "Content-Type: application/json" -d @/etc/assisted-service/assisted-service.ign http://127.0.0.1:8090/api/assisted-install/v1/clusters/$CLUSTER_ID/hosts/$HOST_ID/ignition
