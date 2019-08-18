#!/bin/bash
set -euxo pipefail

# You might want to change these
RAM=8192 #MB
VCPUS=8
BRIDGE=br0


LIBVIRT_IMG_DIR=/var/lib/libvirt/images/container-linux
LIBVIRT_IMG=${LIBVIRT_IMG_DIR}/coreos_production_qemu_image.img

if ! [ -e ${LIBVIRT_IMG} ]; then
  mkdir -p $LIBVIRT_IMG_DIR
  pushd $LIBVIRT_IMG_DIR

  # I don't bother wgetting the signature and checking.  Downloading a
  # signature via HTTPS that I don't trust for any other reason than I
  # downloaded it via HTTPS isn't actually any more secure than just trusting
  # the core-os.net TLS cert.
  wget --continue https://stable.release.core-os.net/amd64-usr/current/coreos_production_qemu_image.img.bz2
  bunzip2 coreos_production_qemu_image.img.bz2
  popd
fi

NAME=${1:-foobar}
QCOW=${LIBVIRT_IMG_DIR}/container-linux-${NAME}.qcow2
if [ -e $NAME ]; then
  echo "Image $QCOW already exists, specify a different name:"
  echo "  $0 <name>"
  exit 1
fi

qemu-img create -f qcow2 -b $LIBVIRT_IMG $QCOW

IGNITION=${LIBVIRT_IMG_DIR}/container-linux-${NAME}.ign
cat > $IGNITION <<EOF
{
  "ignition": {
    "config": {},
    "timeouts": {},
    "version": "2.1.0"
  },
  "networkd": {},
  "passwd": {
    "users": [
      {
        "name": "core",
        "sshAuthorizedKeys": [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDPxHYLaWVh3p0tQPfhJtSPcUAZFvjeSarVUwa5cUg03NFHNu8UFNffWYh3l75FtdQSPhmvFBVL0Xikrj7yCjcODik+k9xvAqBMm6XKOa2rc51y7USJNL8nJyVob3uJOe0d+UWykgI4c+8wiOaZ4rwgkgsaAuKsfhXPgkb8r6Ot9NuOzJ2Eor2vhGw2jujqJNQQQ3wpIWCyx8ZJ3Xp7j1sqMVz7TvgtLxtr69zS5JJPz4OSJO1EWBdPqlBMUx+0N+L5kD8ABnfT+m6w+H3XlBgpxnJtmPAeGi67+gggsTqoDPWtp3gJmlbag0AJblvy1i+UrPdk2wii3gW/xXLWaHhn"
        ]
      }
    ]
  },
  "storage": {
    "files": [
      {
        "filesystem": "root",
        "group": {},
        "path": "/etc/hostname",
        "user": {},
        "contents": {
          "source": "data:,${NAME}",
          "verification": {}
        },
        "mode": 420
      }
    ]
  },
  "systemd": {}
}
EOF

LIBVIRT_XML=${LIBVIRT_IMG_DIR}/container-linux-${NAME}.domain.xml

INSTCMD="HOME=/root virt-install --connect qemu:///system \
  --import \
  --name container-linux-${NAME} \
  --ram $RAM --vcpus $VCPUS \
  --os-type=linux --os-variant=virtio26 \
  --disk path=$QCOW,format=qcow2,bus=virtio \
  --vnc --noautoconsole \
  --print-xml"

if [ -n "$BRIDGE" ]; then
  INSTCMD="$INSTCMD --network bridge=$BRIDGE"
fi

eval $INSTCMD > $LIBVIRT_XML

sed -i 's|type="kvm"|type="kvm" xmlns:qemu="http://libvirt.org/schemas/domain/qemu/1.0"|' "${LIBVIRT_XML}"
sed -i "/<\/devices>/a <qemu:commandline>\n  <qemu:arg value='-fw_cfg'/>\n  <qemu:arg value='name=opt/com.coreos/config,file=${IGNITION}'/>\n</qemu:commandline>" "${LIBVIRT_XML}"

virsh define $LIBVIRT_XML
virsh start container-linux-$NAME
virsh autostart container-linux-$NAME
