#!/bin/sh
set -e

# Puppet Task Name: update_all_images
#
# This task does the dance requried to get docker-compose to use update the container for every service.
#
cd /opt/puppetlabs/hdp
for c in `docker-compose ps --services |sort`; do
  echo "redoing $c"
  docker-compose rm -s -f $c
  docker-compose pull $c
done
docker-compose up -d --remove-orphans
