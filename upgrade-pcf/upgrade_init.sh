if [ ! -f ci/pcf_upgrade_params.yml ]; then
  echo "Creating ci/pcf_upgrade_params.yml"
  cp ci/sample/pcf_upgrade_params_sample.yml ci/pcf_upgrade_params.yml
fi
