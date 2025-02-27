# CommC: a Multi-Purpose COMModity Hardware Cluster

## Installation Instructions

### Prepare nodes:

1. Install Proxmox VE following this [guide](https://pve.proxmox.com/wiki/Installation)
2. Copy the contents of this repository
3. Run the [initialization script](./init.sh): ``./init.sh``

### Create Prxomox cluster:

1. Follow this [guide](https://pve.proxmox.com/wiki/Cluster_Manager) to create and join the cluster

### Create VMs to be used as PCs

1. Use Proxmox'x web UI to create a VM with specs of your liking.
2. Select __vmbr0__ as the bridge of the virtual NIC you want to have internet access.
3. Within the VM, make sure to set a static IP in the range of 192.168.7.[2-254]/24 (Gateway: 192.168.7.1) for the aforementioned NIC.
4. Create a user for the VM using the web UI (Datacenter->Permissions->Users)
5. Assign the user to the VM using the web UI (_VM_->Permissions). For simple users, it is advised to use the role _PVEVMUser_
6. The user can now access their VM via the web UI or by double-clicking the _StartOS_ icon found in every node's desktop

### Create a Kubernetes cluster

1. Create an SDN for the cluster using the web UI (Datacenter->SDN->Zones). Select __VXLAN__ as _Type_ and __1450__ for the _MTU_. Make sure to fill in all the IP addresses of the physical nodes in the _Peer Address List_ (comma separated).
2. On every node you want to participate in the cluster create a VM with two virtual NICs and select __vmbr0__ as bridge for _net0_ and the SDN you created in step 1 for _net1_.
3. Install Ubuntu Server (any modern version) as the guest OS. 
3. Copy the directory [k8s-node-vm](./k8s-node-vm) in all the newly created VMs.
4. Run [microk8s_init.sh](./k8s-node-vm/microk8s_init.sh) with sudo privileges on every node. For a minimal setup run: ``./mimicrok8s_init.sh {node_no} {your_email} 0 0 0 0``. Note that _{node_no}_ is an integer in the range __1-32__.
5. Follow this [guide](https://microk8s.io/docs/clustering) to add all the nodes in a single K8s cluster.