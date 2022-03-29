#!/bin/bash

ARCHIVE_NAME="bloxone-template-$(date +%F).zip"
MAIN_TEMPLATE=main/mainTemplate.json

# Creating archive.
function archive() {
    cd main
    zip -r ../${ARCHIVE_NAME} *
    
    echo "${ARCHIVE_NAME} created."
}

function usage() {
    echo -e "\nUsage: $0 accessPortal=<accessPortal> configServer=<configServer> notificationServer=<notificationServer> pid=<pid>\n"
}

# Patching mainTemplate.
function patchMainTemplate() {
    jq ".variables.hostSetup.accessPortal = \"${accessPortal}\"" ${MAIN_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${MAIN_TEMPLATE}
    jq ".variables.hostSetup.configServer = \"${configServer}\"" ${MAIN_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${MAIN_TEMPLATE}
    jq ".variables.hostSetup.notificationServer = \"${notificationServer}\"" ${MAIN_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${MAIN_TEMPLATE}
    jq ".resources[0].name = \"${pid}\"" ${MAIN_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${MAIN_TEMPLATE}
    
    echo "${MAIN_TEMPLATE} is patched."
}

# Determining arguments.
for ARGUMENT in "$@"
do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    KEY_LENGTH=${#KEY}
    VALUE="${ARGUMENT:$KEY_LENGTH+1}"
    export "$KEY"="$VALUE"
done

if [ -z ${accessPortal} ] || [ -z ${configServer} ] || [ -z ${notificationServer} ] || [ -z ${pid} ]; then
    usage
    exit 0
fi

if [ ! -f ${MAIN_TEMPLATE} ]; then
    echo "Can't find file ${MAIN_TEMPLATE}"
    exit 1
fi

patchMainTemplate
archive
