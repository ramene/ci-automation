#!/bin/bash
set -e

cp /om-alpine /usr/local/bin

# Apply Changes in Opsman
om-alpine -t https://$OPSMAN_HOST -k -u $OPSMAN_USER -p $OPSMAN_PASSWORD apply-changes
