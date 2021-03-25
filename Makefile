NET_NAME = ai-sno-net
VM_NAME = sno-ai-test
VOL_NAME = $(VM_NAME).qcow2
ISO_NAME=ai-sno.iso
LIBVIRT_ISO_PATH = /var/lib/libvirt/images/$(ISO_NAME)

clean: destroy-libvirt

.PHONY: checkenv
checkenv:
ifndef PULL_SECRET
	$(error PULL_SECRET must be defined)
endif

destroy-libvirt:
	echo "Destroying previous libvirt resources"
	NET_NAME=$(NET_NAME) \
	VM_NAME=$(VM_NAME) \
	VOL_NAME=$(VOL_NAME) \
	./virt/virt-delete.sh || true

.PHONY: assisted-service/register-cluster.sh
assisted-service/register-cluster.sh: assisted-service/register-cluster.template checkenv
	sed -e 's/YOUR_PULL_SECRET/${PULL_SECRET}/' $< > $@

# use fcct to add services and scripts to the base.ign
ai-sno.ign: assisted-service base.ign sno-ai.fcc assisted-service/register-cluster.sh
	echo "Generate Ignition"
	podman run --rm --privileged --volume ./:/assets:z quay.io/coreos/fcct:release --pretty --strict --files-dir assets /assets/sno-ai.fcc > ai-sno.ign

$(ISO_NAME): ai-sno.ign
	echo "Generating ISO"
	rm -f $@
	podman run --pull=always --privileged --rm -v .:/data quay.io/coreos/coreos-installer:release iso ignition embed -i /data/ai-sno.ign -o /data/ai-sno.iso /data/image.iso

$(LIBVIRT_ISO_PATH): $(ISO_NAME)
	sudo cp $< $@
	sudo chown qemu:qemu $@

# the resulting VM will start AI onprem and allow the user to install SNO on the VM
# In order to start the installation login to 192.168.126.10:6008
start: network $(LIBVIRT_ISO_PATH)
	echo "Starting ISO"
	RHCOS_ISO=$(LIBVIRT_ISO_PATH) \
	VM_NAME=$(VM_NAME) \
	NET_NAME=$(NET_NAME) \
	./virt/virt-start.sh

# This should be removed, there isn't any network requirements for this installation (except for DHCP)
network:
	echo "Creating network"
	./virt/virt-create-net.sh

.PHONY: ssh
ssh:
	chmod 400 ./ssh/key
	ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ./ssh/key core@192.168.127.10

image.iso:
	echo "Downloading image"
	./download_live_iso.sh $@
