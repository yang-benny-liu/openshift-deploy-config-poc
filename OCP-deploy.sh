#!/bin/bash
#Openshift Deployment
#Version 2018.08.07
#Creator Yang Benny Liu


# Baseline
max_processes=12340
max_cpu_load=75
max_iowait=70
mem_threshold=99
swap_threshold=88
storage_threshold=80
partitions=( / )
service_name=('sshd' 'docker')
process_name=('python')

# Global vars
HOST_PATH="openshift-deploy-config-poc/inventory/hosts"

pre_check() {
    echo "###################################### Git clone repo ######################################"
	git clone https://github.com/yang-benny-liu/openshift-deploy-config-poc.git
	
	echo "###################################### Check requirement ###################################"
	ansible localhost,all -m shell -a 'export GUID=`hostname | cut -d"." -f2`; echo "export GUID=$GUID" >> $HOME/.bashrc'
    ansible -i $HOST_PATH all --list-hosts
    ansible -i $HOST_PATH all -m ping
    ansible -i $HOST_PATH nodes -m shell -a"systemctl status docker | grep Active"
    ansible -i $HOST_PATH all -m shell -a"yum repolist"
	
}

deploy() {
    echo "################################### Run playbook to install ################################"
    ansible-playbook -i hosts /usr/share/ansible/openshift-ansible/playbooks/prerequisites.yml
    ansible-playbook -i hosts /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml
    ansible masters[0] -b -m fetch -a "src=/root/.kube/config dest=/root/.kube/config flat=yes"
}

create_pvs() { 
    export GUID=`hostname|awk -F. '{print $2}'`
    echo "################################### Create 5G PV ################################"
	export volsize="10Gi"
	mkdir /root/pvs
	for volume in pv{1..25} ; do
	cat << EOF > /root/pvs/${volume}
	{
	  "apiVersion": "v1",
	  "kind": "PersistentVolume",
	  "metadata": {
	    "name": "${volume}"
	  },
	  "spec": {
	    "capacity": {
	        "storage": "${volsize}"
	    },
	    "accessModes": [ "ReadWriteOnce" ],
	    "nfs": {
	        "path": "/srv/nfs/user-vols/${volume}",
	        "server": "support1.${GUID}.internal"
	    },
	    "persistentVolumeReclaimPolicy": "Recycle"
	  }
	}
	EOF
	echo "Created def file for ${volume}";
	done;
    
    echo "################################### Create 10G PV ################################"
    export volsize="20Gi"
	for volume in pv{26..50} ; do
	cat << EOF > /root/pvs/${volume}
	{
	  "apiVersion": "v1",
	  "kind": "PersistentVolume",
	  "metadata": {
	    "name": "${volume}"
	  },
	  "spec": {
	    "capacity": {
	        "storage": "${volsize}"
	    },
	    "accessModes": [ "ReadWriteMany" ],
	    "nfs": {
	        "path": "/srv/nfs/user-vols/${volume}",
	        "server": "support1.${GUID}.internal"
	    },
	    "persistentVolumeReclaimPolicy": "Retain"
	  }
	}
	EOF
	echo "Created def file for ${volume}";
	done;
    
    cat /root/pvs/* | oc create -f ¨C
}

verify() {
    echo "###################################### Verify resouces created ######################################"
	oc get nodes
	oc get pod --all-namespaces
	oc get pv
	oc new-project smoke-test
	oc new-app nodejs-mongo-persistent
}
echo "Starting Openshift 3.9 deployment........."
pre_check
deploy
create_pvs
verify
echo "Openshift 3.9 deploy completely!"
