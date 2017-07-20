#!/bin/bash
set -e

#Make om-alpine executable
cp /om-alpine /usr/local/bin
chmod 755 /usr/local/bin/om-alpine

# This function is not used now. Keeping it for future
function fn_om_linux_curl {

    local curl_method=${1}
    local curl_path=${2}
    local curl_data=${3}

     curl_cmd="om-alpine --target https://$OPSMAN_HOST -k \
            --username \"$OPSMAN_USER\" \
            --password \"$OPSMAN_PASSWORD\"  \
            curl \
            --request ${curl_method} \
            --path ${curl_path}"

    if [[ ! -z ${curl_data} ]]; then
       curl_cmd="${curl_cmd} \
            --data '${curl_data}'"
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
echo "Applying Changes ... "
echo "=============================================================================================="
om-alpine --target https://$OPSMAN_HOST -k --username "$OPSMAN_USER" --password "$OPSMAN_PASSWORD" apply-changes
echo "=============================================================================================="
echo "Applied Changes Successfully. "
echo "=============================================================================================="
