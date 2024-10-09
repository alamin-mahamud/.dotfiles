#!/bin/bash

# Exit immediately if a command exits with a non-zero status
# set -e

# Global Variables
K8S_POD_NETWORK_CIDR="10.244.0.0/16"
CALICO_MANIFEST_URL="https://docs.projectcalico.org/manifests/calico.yaml"

# Function: Print a message with a timestamp
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1"
}

# Function: Check if the script is run as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log "Please run as root or use sudo."
        exit 1
    fi
}

# Function: Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}


check_system_resources() {
    CPU_CORES=$(nproc --all)
    MEMORY=$(free -m | awk '/^Mem:/{print $2}')
    DISK_SPACE=$(df / | awk 'NR==2 {print $4}')

    if [ "$CPU_CORES" -lt 2 ]; then
        log "Error: At least 2 CPU cores are required. Detected: $CPU_CORES"
        exit 1
    fi

    if [ "$MEMORY" -lt 2048 ]; then
        log "Error: At least 2GB of RAM is required. Detected: ${MEMORY}MB"
        exit 1
    fi

    if [ "$DISK_SPACE" -lt 20000000 ]; then
        log "Error: At least 20GB of disk space is required. Detected: ${DISK_SPACE}KB"
        exit 1
    fi
}

check_necessary_cmds() {
    for cmd in apt curl modprobe; do
        if ! command_exists "$cmd"; then
            log "Error: $cmd is not installed. Please install it before running the script."
            exit 1
        fi
    done
}

# Function: Pre-flight Checks
pre_flight_checks() {
    log "Performing pre-flight checks..."
    check_necessary_cmds
    check_system_resources
    log "Pre-flight checks passed."
}

# Function: Update and Upgrade System
update_system() {
    log "Updating system packages..."
    apt update && apt upgrade -y
}

# Function: Disable Swap
disable_swap() {
    log "Disabling swap..."
    swapoff -a

    # Permanently disable swap by commenting out swap entries in /etc/fstab
    sed -i '/ swap / s/^/#/' /etc/fstab

    # Verify swap is disabled
    if swapon --show | grep -q .; then
        log "Error: Swap is still enabled."
        exit 1
    fi

    log "Swap disabled successfully."
}

# Function: Load Required Kernel Modules
load_kernel_modules() {
    log "Loading required kernel modules..."
    modprobe overlay
    modprobe br_netfilter

    # Verify modules are loaded
    lsmod | grep -E 'overlay|br_netfilter' >/dev/null 2>&1 || {
        log "Error: Required kernel modules are not loaded."
        exit 1
    }

    log "Kernel modules loaded successfully."
}

# Function: Configure sysctl for Kubernetes
configure_sysctl() {
    log "Configuring sysctl parameters for Kubernetes networking..."
    cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

    sysctl --system

    log "sysctl parameters configured."
}

# Function: Install Docker
install_docker() {
    log "Installing Docker..."

    if ! command_exists docker; then
        apt install -y docker.io
    else
        log "Docker is already installed."
    fi

    log "Enabling and starting Docker service..."
    systemctl enable docker
    systemctl start docker

    log "Configuring Docker to use systemd as the cgroup driver..."
    mkdir -p /etc/docker
    cat <<EOF > /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

    systemctl restart docker

    # Verify Docker is using systemd
    DOCKER_CGROUP_DRIVER=$(docker info | grep -i "Cgroup Driver" | awk '{print $3}')
    if [ "$DOCKER_CGROUP_DRIVER" != "systemd" ]; then
        log "Error: Docker is not using systemd as the cgroup driver."
        exit 1
    fi

    log "Docker installed and configured successfully."
}

# Function: Install Kubernetes Components
install_kubernetes_components() {
    log "Adding Kubernetes apt repository..."
    sudo apt-get install -y apt-transport-https ca-certificates curl gpg
    curl -fsSL https://pkgs.k8s.io/core:/stable/deb/Release.key | sudo apt-key add -
    echo "deb https://pkgs.k8s.io/core:/stable/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

    log "Installing kubelet, kubeadm, and kubectl..."
    sudo apt update
    sudo apt install -y kubelet kubeadm kubectl

    log "Holding kubelet, kubeadm, and kubectl at current versions..."
    sudo apt-mark hold kubelet kubeadm kubectl
}

# Function: Initialize Kubernetes Cluster
initialize_kubernetes() {
log "Initializing Kubernetes single-node cluster..."

# Initialize kubeadm with pod network CIDR
# TODO
kubeadm init  \
    --pod-network-cidr=$K8S_POD_NETWORK_CIDR \
    --apiserver-advertise-address=$(hostname -I | awk '{print $1}') \
    --cri-socket=unix:///var/run/docker/containerd/containerd.sock


# └─(18:09:00 on dev ✖ ✹ ✚)──> sudo kubeadm init  \                                                                                                                                                                                                                                                         1 ↵ ──(Tue,Oct08)─┘
#     --pod-network-cidr=$K8S_POD_NETWORK_CIDR \
#     --apiserver-advertise-address=$(hostname -I | awk '{print $1}') \
#     --cri-socket=unix:///var/run/docker/containerd/containerd.sock
# [init] Using Kubernetes version: v1.31.0
# [preflight] Running pre-flight checks
# W1008 18:09:05.098881   87576 checks.go:1080] [preflight] WARNING: Couldn't create the interface used for talking to the container runtime: failed to create new CRI runtime service: validate service connection: validate CRI v1 runtime API for endpoint "unix:///var/run/docker/containerd/containerd.sock": rpc error: code = Unavailable desc = connection error: desc = "transport: Error while dialing: dial unix /var/run/docker/containerd/containerd.sock: connect: no such file or directory"
#         [WARNING FileExisting-socat]: socat not found in system path
# [preflight] Pulling images required for setting up a Kubernetes cluster
# [preflight] This might take a minute or two, depending on the speed of your internet connection
# [preflight] You can also perform this action beforehand using 'kubeadm config images pull'
# error execution phase preflight: [preflight] Some fatal errors occurred:
# failed to create new CRI runtime service: validate service connection: validate CRI v1 runtime API for endpoint "unix:///var/run/docker/containerd/containerd.sock": rpc error: code = Unavailable desc = connection error: desc = "transport: Error while dialing: dial unix /var/run/docker/containerd/containerd.sock: connect: no such file or directory"[preflight] If you know what you are doing, you can make a check non-fatal with `--ignore-preflight-errors=...`
# To see the stack trace of this error execute with --v=5 or higher


log "Kubernetes control plane initialized."
}

# Function: Configure kubectl for Current User
configure_kubectl() {
    log "Configuring kubectl for the current user..."
    mkdir -p $HOME/.kube
    cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    chown $(id -u):$(id -g) $HOME/.kube/config

    log "kubectl configured successfully."
}


# Function: Allow Scheduling Pods on Control Plane
allow_pods_on_control_plane() {
    log "Allowing pods to be scheduled on the control plane node..."
    kubectl taint nodes --all node-role.kubernetes.io/control-plane-
    kubectl taint nodes --all node-role.kubernetes.io/master-
    log "Pods can now be scheduled on the control plane node."
}

# Function: Install Pod Network (Calico)
install_pod_network() {
    log "Installing Calico pod network..."
    kubectl apply -f $CALICO_MANIFEST_URL
    log "Calico pod network installed."
}

# Function: Generate Kubeadm Join Command for Worker Nodes
generate_join_command() {
    log "Generating kubeadm join command for worker nodes..."

    # Retrieve the join command from the control plane node
    kubeadm token create --print-join-command
}

# Function: Join Worker Node to Control Plane
join_worker_node() {
    log "Joining this node as a worker to an existing control plane..."

    read -p "Enter the kubeadm join command provided by the control plane: " join_command
    eval "$join_command"

    log "Worker node joined successfully."
}

# Function: Verify Kubernetes Installation
verify_installation() {
    log "Verifying Kubernetes cluster status..."
    kubectl get nodes

    log "Listing all pods in all namespaces..."
    kubectl get pods --all-namespaces

    log "Kubernetes installation verified successfully."
}

# Main Function: Orchestrate the Setup
main() {
    check_root
    pre_flight_checks
    update_system
    disable_swap
    load_kernel_modules
    configure_sysctl
    install_docker
    install_kubernetes_components

    # Prompt user for control plane or worker node setup
    echo "Select node type for setup:"
    echo "1) Control Plane (Master Node)"
    echo "2) Worker Node"

    read -p "Enter your choice (1/2): " node_type

    if [ "$node_type" == "1" ]; then
        initialize_kubernetes
        configure_kubectl
        allow_pods_on_control_plane
        install_pod_network
        generate_join_command
        verify_installation
    elif [ "$node_type" == "2" ]; then
        join_worker_node
    else
        log "Invalid option. Please enter 1 for Control Plane or 2 for Worker Node."
        exit 1
    fi

    log "Setup completed successfully."
}

# Execute the main function
main
