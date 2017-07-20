#!/bin/bash
set -e

# for rsamban/pcf-om (alpine image)
cp /om-alpine /usr/local/bin/om

# for ubuntu images
# apt-get update
# apt-get install -y wget
# wget https://github.com/pivotal-cf/om/releases/download/0.21.0/om-linux -O /usr/local/bin/om

chmod +x /usr/local/bin/om


# Apply Changes in Opsman
om -t https://$OPSMAN_HOST -k -u $OPSMAN_USER -p $OPSMAN_PASSWORD apply-changes
