## Creating service principals
#### start azure cli docker container
1. open command prompt. _Note: all references to this command prompt window will be  refered as **azure command window** in the document below._
2. run command `docker run -it azuresdk/azure-cli-python:latest`
3. run `az login` (follow prompts to complete login)

#### set the properties in mcparams.sh
1. run `git clone https://github.com/ecsteam/mastercard`
2. run `cd mastercard/bootstrap/create_sps`
3. make copy of create_sp_and_roles_params_sample.sh (call it mcparams.sh)
4. change following properties in mcparams.sh  

	- `NETWORK_RESOURCE_GROUP` - name for network resource group  
	- `SUBSCRIPTION_ID`- in **azure command window**, run `az account list` and copy subscription `id` from the json response.
	- `AZURE_LOCATION` - in **azure command window**, run `az account list-locations` and copy `name` from json response  
	- `CI_SERVICE_PRINCIPAL_NAME` - automation service principal name, used in automation scripts
	- `CI_CLIENT_SECRET` - secret for `CI_SERVICE_PRINCIPAL_NAME` 
	- `PCF_SERVICE_PRINCIPAL_NAME` - pcf service principal name, this will be used in `Azure Config` in ops manager. (e.g: `pcfazurestage`)
	- `PCF_CLIENT_SECRET` - secret for `PCF_SERVICE_PRINCIPAL_NAME`  
	- `NET_RG_READ_ONLY_ROLE_NAME` - role that will have read only access to `NETWORK_RESOURCE_GROUP`
	- `NET_RG_READ_ONLY_ROLE_DEF_FILE_NAME` - file name that has role definition
	- `AZURE_SB_SERVICE_PRINCIPAL_NAME` - pcf service principal name, this will be used in `Azure Config` in ops manager. (e.g: `pcfazurestage`)
	- `AZURE_SB_CLIENT_SECRET` - secret for `AZURE_SB_SERVICE_PRINCIPAL_NAME`  

5. run `docker ps` and copy the `CONTAINER ID`
6. run `docker cp bootstrap <CONTAINER ID>:/root`  

#### Create service principals
1. in **azure command window**, run `cd /root`
2. in **azure command window**, run `./create_sp_and_roles.sh mcparams.sh`.  
3. **Note:** Do not loose the `mcparams.sh` file or checkin to any source control repository.
