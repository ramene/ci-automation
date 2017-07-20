if [ ! -f ci/pcf_install_params.yml ]; then
  echo "Creating ci/pcf_install_params.yml"
  cp ci/sample/pcf_install_params.yml ci/pcf_install_params.yml
fi
