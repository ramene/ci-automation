#!/bin/bash

set -e

export http_proxy=
export https_proxy=

cp /om-alpine /usr/local/bin
chmod 755 /usr/local/bin/om-alpine

echo "=============================================================================================="
echo "Staging products for deployments..."
echo "=============================================================================================="

uaac target https://${OPSMAN_HOST}/uaa --skip-ssl-validation > /dev/null 2>&1
uaac token owner get opsman ${OPSMAN_USER} -s "" -p ${OPSMAN_PASSWORD} > /dev/null 2>&1
export opsman_bearer_token=$(uaac context | grep access_token | awk -F ":" '{print$2}' | tr -d ' ')


#product_types=$(curl -s -k -X GET -H "Content-Type: application/json" -H "Authorization: Bearer ${opsman_bearer_token}" "https://${OPSMAN_HOST}/api/v0/deployed/products" |jq '.[] | .type' | tr -d '"')
product_types=$(curl -s -k -X GET -H "Content-Type: application/json" -H "Authorization: Bearer ${opsman_bearer_token}" "https://${OPSMAN_HOST}/api/v0/available_products" |jq '.[] | .name' | tr -d '"' | sort | uniq)


for product in $product_types; do
    #echo "product=$product"
    product_versions=$(curl -s -k -X GET -H "Content-Type: application/json" -H "Authorization: Bearer ${opsman_bearer_token}" "https://${OPSMAN_HOST}/api/v0/available_products" | jq --arg product "$product" ' .[] | select ( .name == $product) | .product_version' | tr -d '"')
    product_version=(${product_versions// / })
    #echo "product_version=$product_version"
    if [[ ${#product_version[@]} > 1 ]]; then
        if [[ ${product_version[0]} > ${product_version[1]} ]]; then
            new_version=${product_version[0]}
        else
            new_version=${product_version[1]}
        fi
        echo "product=$product,new_version=$new_version"
	# stage product
	# TODO: check if the product is already staged.
	echo "Staging $product version $new_version for deployment"
	om-alpine -t https://$OPSMAN_HOST -k -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" stage-product --product-name $product --product-version $new_version
    fi
done
