#!/bin/sh
# A Kubernetes node, ready for kubeadm and offline: containerd (systemd
# cgroups), kubeadm, kubelet and kubectl pinned, the kernel settings kubeadm
# checks, and the control plane and flannel images saved as archives that
# brokelabs-k8s-images.service imports into containerd at boot, before the
# kubelet. Setup scripts run `systemctl start brokelabs-k8s-images` (it waits
# for the import) before kubeadm init or join.
set -eu
export DEBIAN_FRONTEND=noninteractive

K8S_MINOR=1.36
K8S_VERSION=1.36.6
FLANNEL_VERSION=v0.28.10
FLANNEL_SHA256=393bdbce53eb50c8eb97dd513b218518b7d6e7985dc7b889be956e112a711084
IMAGES=/var/lib/brokelabs/images

apt-get update
apt-get install -y --no-install-recommends ca-certificates curl gpg containerd skopeo conntrack socat

# Kubernetes packages from pkgs.k8s.io, held at the pinned version.
install -m 0755 -d /etc/apt/keyrings
curl -fsSL "https://pkgs.k8s.io/core:/stable:/v$K8S_MINOR/deb/Release.key" | gpg --dearmor -o /etc/apt/keyrings/kubernetes.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes.gpg] https://pkgs.k8s.io/core:/stable:/v$K8S_MINOR/deb/ /" > /etc/apt/sources.list.d/kubernetes.list
apt-get update
pkg=$(apt-cache madison kubeadm | awk -v v="$K8S_VERSION" '$3 ~ "^"v"-" {print $3; exit}')
[ -n "$pkg" ] || { echo "kubeadm $K8S_VERSION not found" >&2; exit 1; }
apt-get install -y --no-install-recommends "kubeadm=$pkg" "kubelet=$pkg" "kubectl=$pkg" cri-tools kubernetes-cni
apt-mark hold kubeadm kubelet kubectl
systemctl enable kubelet containerd

# Kernel settings kubeadm checks.
printf 'overlay\nbr_netfilter\n' > /etc/modules-load.d/kubernetes.conf
cat > /etc/sysctl.d/90-kubernetes.conf <<'CONF'
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
CONF

# kubeadm derives a node name from the hostname, "(none)" while building:
# list the images with an explicit one.
kubeadm_config=$(mktemp)
cat > "$kubeadm_config" <<CONF
apiVersion: kubeadm.k8s.io/v1beta4
kind: InitConfiguration
nodeRegistration: {name: image-builder}
---
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
kubernetesVersion: v$K8S_VERSION
CONF
kubeadm_images=$(kubeadm config images list --config "$kubeadm_config")
rm -f "$kubeadm_config"

# containerd with systemd cgroups (like the kubelet) and kubeadm's pause image.
pause=$(echo "$kubeadm_images" | grep /pause:)
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
# CNI plugins live in /opt/cni/bin (kubernetes-cni, flannel), not in Debian's
# /usr/lib/cni.
sed -i "s/SystemdCgroup = false/SystemdCgroup = true/; s#sandbox_image = .*#sandbox_image = \"$pause\"#; s#sandbox = '.*'#sandbox = '$pause'#; s#bin_dir = .*#bin_dir = \"/opt/cni/bin\"#; s#bin_dirs = .*#bin_dirs = ['/opt/cni/bin']#" /etc/containerd/config.toml
grep -q 'SystemdCgroup = true' /etc/containerd/config.toml
grep -qE "bin_dirs? = .*/opt/cni/bin" /etc/containerd/config.toml
printf 'runtime-endpoint: unix:///run/containerd/containerd.sock\nimage-endpoint: unix:///run/containerd/containerd.sock\n' > /etc/crictl.yaml

# flannel's manifest, pinned by checksum, next to the images.
mkdir -p /etc/brokelabs "$IMAGES"
curl -fsSL -o /etc/brokelabs/kube-flannel.yml "https://github.com/flannel-io/flannel/releases/download/$FLANNEL_VERSION/kube-flannel.yml"
echo "$FLANNEL_SHA256  /etc/brokelabs/kube-flannel.yml" | sha256sum -c -
echo "$K8S_VERSION" > /etc/brokelabs/kubernetes-version

for image in $kubeadm_images \
             $(sed -n 's/^ *image: *//p' /etc/brokelabs/kube-flannel.yml | sort -u); do
  skopeo copy --override-os linux --override-arch amd64 \
    "docker://$image" "docker-archive:$IMAGES/$(echo "$image" | tr '/:@' '___').tar:$image"
done

cat > /etc/systemd/system/brokelabs-k8s-images.service <<'UNIT'
[Unit]
Description=Import the preloaded Kubernetes images into containerd
Requires=containerd.service
After=containerd.service
Before=kubelet.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/sh -c 'for f in /var/lib/brokelabs/images/*.tar; do ctr -n k8s.io images import "$f" >/dev/null; done'

[Install]
WantedBy=multi-user.target
UNIT
systemctl enable brokelabs-k8s-images

apt-get purge -y skopeo gpg
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*
cloud-init clean --logs
