#!/bin/bash
set -ex

CWD=$(pwd)

if [[ "$IAAS" == "vSphere" ]]; then
    echo "Configuring ops manager for $IAAS"
    pcf-automation/pcf-opsman/install-pcf/ci/scripts/config-director-vSphere.sh
fi
