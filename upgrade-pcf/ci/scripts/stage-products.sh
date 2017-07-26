#!/bin/bash

set -e

cp /om-alpine /usr/local/bin
chmod 755 /usr/local/bin/om-alpine2

function fn_om_linux_curl {

    local curl_method=${1}
    local curl_path=${2}
    local curl_data=${3}

     curl_cmd="./om-alpine --target https://$OPSMAN_HOST -k --username \"$OPSMAN_USER\" --password \"$OPSMAN_PASSWORD\"  \
            curl --request ${curl_method} --path ${curl_path}"

    if [[ ! -z ${curl_data} ]]; then
       curl_cmd="${curl_cmd} --data '${curl_data}'"
    fi

    echo ${curl_cmd} > /tmp/rqst_cmd.log
    exec_out=$(((eval $curl_cmd | tee /tmp/rqst_stdout.log) 3>&1 1>&2 2>&3 | tee /tmp/rqst_stderr.log) &>/dev/null)

    if [[ $(cat /tmp/rqst_stderr.log | grep "Status:" | awk '{print$2}') != "200" ]]; then
      echo "Error Call Failed ...."
      echo $(cat /tmp/rqst_stderr.log)
      exit 1
    else
      echo $(cat /tmp/rqst_stdout.log)
    fi
}


echo "=============================================================================================="
echo "Staging products for deployments..."
echo "=============================================================================================="

product_types=$(fn_om_linux_curl "GET" "/api/v0/available_products" | jq '.[] | .name' | tr -d '"' | sort | uniq)
echo $product_types

for product in $product_types; do
    #echo "product=$product"
    product_versions=$(fn_om_linux_curl "GET" "/api/v0/available_products" | jq --arg product "$product" ' .[] | select ( .name == $product) | .product_version' | tr -d '"')

    product_version=(${product_versions// / })
    #echo "product_version=$product_version"
    new_version=""
    if [[ ${#product_version[@]} > 1 ]]; then
	for p_ver in "${product_version[@]}"; do
	    if [[ -z $new_version ]]; then
                new_version=$p_ver
	    else
                if [[ $new_version < $p_ver ]]; then
                    new_version=$p_ver
		fi
	    fi
	done
	# stage product
	# TODO: check if the product is already staged.
    else
        new_version=$product_version
    fi
    echo "Staging $product version $new_version for deployment"
    om-alpine -t https://$OPSMAN_HOST -k -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" stage-product --product-name $product --product-version $new_version
done
