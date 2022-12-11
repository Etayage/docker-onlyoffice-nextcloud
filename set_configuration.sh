#!/bin/bash

printf "launching NC "

LAUNCHED=$(docker logs app-server | grep "ready" | wc -l)
while [ $LAUNCHED -lt 1 ]
do
  printf '.'
  sleep 1
  LAUNCHED=$(docker logs app-server | grep "ready" | wc -l)
done
printf '\n'
echo " NC launched"

echo "configuring NC"

source .env

docker exec -u www-data app-server php occ --no-warnings config:system:delete overwrite.cli.url
docker exec -u www-data app-server php occ --no-warnings config:system:set trusted_domains 0 --value="${TRUSTED_DOMAINS}"

set -x

docker exec -u www-data app-server php occ --no-warnings config:system:get trusted_domains >> trusted_domain.tmp

if ! grep -q "nginx-server" trusted_domain.tmp; then
    TRUSTED_INDEX=$(cat trusted_domain.tmp | wc -l);
    docker exec -u www-data app-server php occ --no-warnings config:system:set trusted_domains $TRUSTED_INDEX --value="nginx-server"
fi

rm trusted_domain.tmp

docker exec -u www-data app-server php occ --no-warnings app:install onlyoffice
docker exec -u www-data app-server php occ --no-warnings config:system:set onlyoffice DocumentServerUrl --value="/ds-vpath/"
docker exec -u www-data app-server php occ --no-warnings config:system:set onlyoffice DocumentServerInternalUrl --value="http://onlyoffice-document-server/"
docker exec -u www-data app-server php occ --no-warnings config:system:set onlyoffice StorageUrl --value="http://nginx-server/"

echo "NC configured"
