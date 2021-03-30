Start a LiveCD that runs the Assisted-installer and allow the user to install the current node as Single Node OpenShift

# How to run - automatic makefile
- Set PULL_SECRET environment variable to your pull secret
  
  You can get the pull secret from here: https://cloud.redhat.com/openshift/install/pull-secret 
- `make start` - Spins up a VM with the the liveCD. This will automatically perform the following actions:
	- Download the RHCOS live ISO
	- Generate Ignition config with Assisted-installer-onprem, register-cluster.service and assisted-intsaller-agent.service.
	- Embed the Ignition to the ISO.
	- Create a libvirt network & VM
	- Boot the VM with that ISO
- You can now monitor the progress and complete the installation using the assisted-installer UI `http://192.168.127.10:8080/clusters`
- You can debug the system with `make ssh` and monitor these services `assisted-servcie.service`, `register-cluster.service` and `agent.service`

# Other notes

* Default release image is quay.io/openshift-release-dev/ocp-release-nightly:4.8.0-0.nightly-2021-03-16-221720,
  you can override it by setting the release_image in assisted-service/onprem-enviornment under OPENSHIFT_VERSIONS.
