# Getting started

To access the automation scripts

```
$ git clone https://github.com/ecsteam/pcf-automation and cd to pcf-automation directory.
```

Bootstrap script for azure has two parts. 

1. `pcf-automation/bootstrap/azure/create_sps/create_sp_and_roles.sh` script creates service principals and role definitions/assignments required for pipeline.
2.  `pcf-automation/bootstrap/azure/bootstrap.sh` script deploys concourse in docker.

# `create_sp_and_roles.sh`

This script should be run as **global admin.** This script will create 3 service principals, 3 resource groups and one custom role definition.  

`CI_SERVICE_PRINCIPAL_NAME` - The service principal is used to run all the automation scripts in pipeline.  
`PCF_SERVICE_PRINCIPAL_NAME` - The service principal is used to configure PCF Ops manager director.  
`AZURE_SB_SERVICE_PRINCIPAL_NAME` - The service principal will be used to configure azure service broker.  
`NET_RG_READ_ONLY_ROLE_NAME` - The custom role name
`PCF_RESOURCE_GROUP` - The resource group where all the PCF components except `vnet` and `public ips` will be provisioned. Following are the roles defined on this resource group.  

 - service principal `CI_SERVICE_PRINCIPAL_NAME ` will inherit `Contributor` role.
 - service principal `PCF_SERVICE_PRINCIPAL_NAME` will be assigned `Contributor` role.  

 
`NETWORK_RESOURCE_GROUP` - The resource group where `vnet` and `public ips` will be provisioned. Following are the roles defined on this resource group.  

- service principal `CI_SERVICE_PRINCIPAL_NAME ` will inherit `Contributor` role.
- service principal `PCF_SERVICE_PRINCIPAL_NAME` will be assigned `NET_RG_READ_ONLY_ROLE_NAME` custom role (to give read only access to `NETWORK_RESOURCE_GROUP`)  

`AZURE_SB_RESOURCE_GROUP` - The resource group where all the azure service broker components (any any resources provisioned in marketplace) are provisioned. Following are the roles defined on this resource group.

- service principal `CI_SERVICE_PRINCIPAL_NAME ` will inherit `Contributor` role.
- service principal `AZURE_SB_SERVICE_PRINCIPAL_NAME` will be assigned `Contributor` role.  

# Parametes for create_sp_and_roles.sh - `create_sp_and_roles_params.yml`.

`FOUNDATION` - name of the foundation. (e.g: dev,prod etc.)  
`NETWORK_RESOURCE_GROUP` - name of the network resource group (e.g: ${FOUNDATION}pcfnetrg)  
`PCF_RESOURCE_GROUP` - name of the pcf resource group (e.g: ${FOUNDATION}pcfrg)  
`AZURE_SB_RESOURCE_GROUP` - name of the resource group for azure service broker (e.g: ${FOUNDATION}azuresbrg)  
`AZURE_LOCATION` - azure location  

`SUBSCRIPTION_ID` - subscription id  
`PCF_SERVICE_PRINCIPAL_NAME` - pcf service principal name (e.g: ${FOUNDATION}boshsp)  
`PCF_CLIENT_SECRET` -   
`NET_RG_READ_ONLY_ROLE_NAME` - role name that defines read only access to network resource group (e.g: ${FOUNDATION}netRgReadOnlyRoleName)  
`NET_RG_READ_ONLY_ROLE_DEF_FILE_NAME` - file name that has definition for role `NET_RG_READ_ONLY_ROLE_NAME` (e.g: etRgReadOnlyRoleDef.json)  

`CI_SERVICE_PRINCIPAL_NAME` - automation service principal name (e.g: ${FOUNDATION}cisp)  
`CI_CLIENT_SECRET` -   
`AZURE_SB_SERVICE_PRINCIPAL_NAME` - service principal to configure azure service broker (e.g: `${FOUNDATION}sbsp`)  

`AZURE_SB_CLIENT_SECRET` - 

### Running the script


```
$ cd pcf-automation/bootstrap/azure/create_sps/
$ cp create_sp_and_roles_params_sample.sh create_sp_and_roles_params.sh
	edit the params file as needed
$ az login
	login to the browser as global admin
$ ./create_sp_and_roles.sh create_sp_and_roles_params.sh
```

**Note:** note down `PCF_APPLICATION_ID` and `AZURE_SB_APPLICATION_ID` from the output. These are needed when configuring ops manager director and azure service broker respectively.


# `bootstrap.sh`

### Pre Run
Create key-pair to login to concourse vm

```
$ ssh-keygen -t rsa -f concourse_key -C ubuntu
```

### Run
This script will install concourse system using `docker-compose`

```
$ cd pcf-automation/bootstrap/azure
$ cp bootstrap_params_sample.sh bootstrap_params.sh
	edit the params file as needed
$ ./bootstrap.sh bootstrap_params.sh
```
This script creates following 

- Create a resource group for bootstrap components
- create a vnet and a subnet
- create a network security group to allow ssh (22) and RDP (443)
- Create concourse vm; install docker; and run concourse using docker-compose. Concourse is accessible in public domain on port 443
- Create windows jumpbox vm (to ssh to concourse vm if needed as ssh is not allowed from internal corporate network)

**Note** Both windows jumpbox and concourse vm is accessible form public domain. Once express route is established, comment out the parts of the script that creates public ip.

### Post Run
* Create A record for `CONCOURSE_HOST` and point it to `CONCOURSE_PIP`
* save the file `<SELF_GEN_TLS_CERT_FILE_PREFIX>tls_cert.crt`. You will need it to login to concourse later.


## Logging into concourse

```
# get the public ip of concourse
$ CONCOURSE_PIP=$(az network public-ip show -g "$BOOTSTRAP_RESOURCE_GROUP" -n "$CONCOURSE_PIP_NAME" | jq .ipAddress | tr -d '"')
# to login to browser, enter following in the browser address field
https://<CONCOURSE_PIP>:443
# download fly from the concourse web and add it to your path
# to login with fly command
$ cd pcf-automation
$ fly -t ecs_azure login -c https://<CONCOURSE_PIP>/ --ca-cert ./pcf-automation/bootstrap/concourse/<SELF_GEN_TLS_CERT_FILE_PREFIX>tls_cert.crt
	SELF_GEN_TLS_CERT_FILE_PREFIX - set in parameter file
```

# Parameters for bootstrap.sh - `bootstrap_params.sh`
`ORG` - org name (e.g: ecs)  
`AZURE_SP_CI_USER` - ci service principal user  
`AZURE_SP_CI_PASSWORD` - ci service principal password  
`AZURE_TENANT_ID` - azure tenant id  

`SUBSCRIPTION_ID` - subscription id  
`AZURE_LOCATION` - azure location  
`BOOTSTRAP_RESOURCE_GROUP` - bootstrap resource group (e.g: `pcfbootstrap${ORG})`  
`BOOTSTRAP_STORAGE_NAME` - boostrap storage account name (e.g: ecsbootstrap)  
`BOOTSTRAP_VNET_NAME` - bootstrap vnet name (e.g: pcfbootstrapvnet)  
`BOOTSTRAP_VNET_CIDR` - bootstrap vnet cidr (e.g: 10.1.0.0/16)  
`NETWORKS_DNS` - 168.63.129.16  
`BOOTSTRAP_SUBNET_NAME` - bootstrap subnet name (e.g: concoursesubnet)  
`BOOTSTRAP_SUBNET_CIDR` - bootstrap subnet cidr (e.g: 10.1.1.0/24)  
`CONCOURSE_NSG` - network security group to allow connections to concoruse - (e.g: concoursensg)  
`CONCOURSE_PIP_NAME` - public ip name for concourse vm (e.g: concoursepip)  
`CONCOURSE_NIC_NAME` - nic name for concourse vm (e.g: concoursenic)  
`CONCOURSE_PRIVATE_IP` - private ip for concourse vm (e.g: 10.1.1.5)  
`CONCOURSE_VM_NAME` - concourse vm name. (e.g: concoursevm)  
`CONCOURSE_VM_USER=ubuntu  
`CONCOURSE_IMAGE_URN="Canonical:UbuntuServer:14.04.5-LTS:14.04.201703230"  
`CONCOURSE_PUBLIC_KEY_FILE` - public key file name (e.g: concourse_key.pub)  
`CONCOURSE_PRIVATE_KEY_FILE` - private key file name (e.g: concourse_key)  
`CREATE_SELF_SIGNED_CERT` - yes  
`CONCOURSE_HOST` - host name for concourse (optional)  
`CONCOURSE_BASIC_AUTH_PASSWORD` - password to access concourse  
`CONCOURSE_PORT` - 443  
`CONCOURSE_PROTOCOL` - https  
`CONCOURSE_OS_DISK_SIZE` - 120  
`CONCOURSE_VM_SIZE` - Standard_DS2_v2  

`WIN_BOOTSTRAP_PIP_NAME` - public ip name for windows jump box (e.g: bootstrapwinpip)  
`WIN_BOOTSTRAP_NIC_NAME` - nic name for windows jumpbox (e.g: bootstrapwinnic)  
`WIN_BOOTSTRAP_PRIVATE_IP` - private ip for windows jumpbox (e.g: 10.1.1.6)  
`WIN_BOOTSTRAP_IMAGE_URN` - "MicrosoftWindowsServer:WindowsServer:2016-Datacenter:latest"  
`WIN_BOOTSTRAP_VM_NAME` - windows jump box vm name (e.g: bootstrapwinvm)  
`WIN_BOOTSTRAP_VM_USER` - windows admin login name (e.g: ecs)  
`WIN_BOOTSTRAP_VM_PASSWORD`  - 

# Parametes for create_sp_and_roles.sh - `create_sp_and_roles_params_<FOUNDATION>.yml`.

`FOUNDATION` - name of the foundation. dev/prod etc.  
`NETWORK_RESOURCE_GROUP` - name of the network resource group (e.g: `${FOUNDATION}pcfnetrg`)  
`PCF_RESOURCE_GROUP` - name of the pcf resource group (e.g: `${FOUNDATION}pcfrg`)  
`AZURE_SB_RESOURCE_GROUP` - name of the resource group for azure service broker (e.g: `${FOUNDATION}azuresbrg`)  
`AZURE_LOCATION` - azure location  

`SUBSCRIPTION_ID` - subscription id  
`PCF_SERVICE_PRINCIPAL_NAME` - pcf service principal name (e.g: `${FOUNDATION}boshsp`)  
`PCF_CLIENT_SECRET` -   
`NET_RG_READ_ONLY_ROLE_NAME` - role name that defines read only access to network resource group (e.g: `${FOUNDATION}netRgReadOnlyRoleName`)  
`NET_RG_READ_ONLY_ROLE_DEF_FILE_NAME` - file name that has definition for role `NET_RG_READ_ONLY_ROLE_NAME` (e.g: NetRgReadOnlyRoleDef.json)  

`CI_SERVICE_PRINCIPAL_NAME` - automation service principal name (e.g: `${FOUNDATION}cisp`)  
`CI_CLIENT_SECRET` -   

`AZURE_SB_SERVICE_PRINCIPAL_NAME` - service principal to configure azure service broker (e.g: `${FOUNDATION}sbsp`)  
`AZURE_SB_CLIENT_SECRET` -   
  




