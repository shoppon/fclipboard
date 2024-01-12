#!/bin/bash

set -ex

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname ${SCRIPT})
WORKSPACE=$(dirname ${SCRIPTPATH})

rm -rf ${WORKSPACE}/apis/out/python
rm -rf ${WORKSPACE}/apis/out/dart
rm -rf ${WORKSPACE}/provider/provider/clients/v1

api_file=/Users/shoppon/code/fclipboard/apis/provider-v1.yaml

docker run --rm \
    -v "$(dirname $(readlink -f $api_file)):/local" openapitools/openapi-generator-cli generate \
    -i /local/${api_file##*/} \
    -g python \
    -o /local/out/python \
    --package-name provider.clients.v1

docker run --rm \
    -v "$(dirname $(readlink -f $api_file)):/local" openapitools/openapi-generator-cli generate \
    -i /local/${api_file##*/} \
    -g dart \
    -o /local/out/dart

cp -r ${WORKSPACE}/apis/out/python/provider/clients/v1 ${WORKSPACE}/provider/provider/clients/

rm -rf ${WORKSPACE}/apis/out/python

# HACK(xp): update http dependency
sed -i '' "s/http: .*/http: '>=0.13.0'/g" ${WORKSPACE}/apis/out/dart/pubspec.yaml

echo "Done generating clients"
