#!/bin/sh
set -e

# Puppet Task Name: use_updated_image
#
# This task does the dance requried to get docker-compose to use an updated container.
#
cd /opt/puppetlabs/hdp
docker-compose rm -s -f $PT_service
docker-compose pull $PT_service
docker-compose up -d --remove-orphans
