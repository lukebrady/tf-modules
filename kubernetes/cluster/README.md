# Kubernetes Cluster Module

This module provisions the infrastructure for a small Kubernetes cluster on EC2 instances. It ships with two bootstrap scripts that prepare instances to run Kubernetes and join them together.

## Bootstrap Scripts

The `templates` directory contains Bash templates rendered by Terraform as user data for the control plane and worker nodes. Both scripts share common setup steps and differ in how they initialise or join the cluster.

### Shared setup

Both scripts perform the following actions:

1. **Install base packages.** Update apt repositories and install tools such as `curl`, `awscli`, and transport certificates required for subsequent downloads.
2. **Disable swap and load kernel modules.** Kubernetes requires swap to be disabled. The scripts also load `overlay` and `br_netfilter` modules and configure sysctl settings to allow IP forwarding and bridged IPv4/IPv6 traffic.
3. **Install and configure containerd.** Containerd is installed from the Docker apt repository. A default configuration is generated and patched so that the cgroup driver uses `systemd`, which matches the kubelet's expectations. The service is then enabled and restarted.
4. **Install Kubernetes components.** The scripts add the official Kubernetes apt repository, install `kubelet`, `kubeadm`, and `kubectl`, and mark them on hold to avoid unintended upgrades.

### Control plane script

`bootstrap-control-plane.sh.tpl` performs additional steps to bring up the cluster:

1. **Initialise the control plane.** Runs `kubeadm init` with the provided pod CIDR to create a single‑node control plane.
2. **Configure kubectl access.** Copies `/etc/kubernetes/admin.conf` to the invoking user's kubeconfig so `kubectl` can manage the cluster.
3. **Install a CNI plugin.** Applies the Flannel manifest to provide pod networking across nodes.
4. **Publish the worker join command.** Generates a `kubeadm token` join command and uploads it to an S3 bucket under `<cluster_name>/join.sh` for workers to consume.

### Worker script

`bootstrap-worker.sh.tpl` waits for the control plane to be ready and then joins the cluster:

1. **Retrieve the join script.** Polls the same S3 bucket for `join.sh` produced by the control plane script.
2. **Join the cluster.** Once available, marks the script executable and executes it, which runs `kubeadm join` with the token and discovery information.

With these scripts, the control plane node initialises the cluster and publishes the join instructions, while worker nodes configure themselves and join when the instructions become available.

