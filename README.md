# openshift-deploy-config-poc

This is a HA deploy & config poc for openshift 3.9. 

Complete the basic HA deployment, Networkpolicy configuration, Metrics & Logging, Service Catalog, Multitenancy Clients, Resource Limit and Jekins CICD workflow


You can refer to the host file configuration in inventory directory for openshift platform deployment


The quota-file folder is used to define resource limitation range, it is with referrence: https://github.com/redhat-cop/openshift-toolkit/tree/master/quota-management


The appier/params applier/projects applier/templates folders are used to create project/bc/dc for clients，it is same as using openshift-applier
