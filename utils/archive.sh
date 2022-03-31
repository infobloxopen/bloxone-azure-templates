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
    echo -e "\nUsage: $0 accessPortal=<accessPortal> configServer=<configServer> imageOffer=<imageOffer> imagePublisher=<imagePublisher> imageSku=<imageSku> imageVersion=<imageVersion> notificationServer=<notificationServer> pid=<pid>"
      echo -e "Required parameters:\n imageOffer\n imagePublisher\n imageSku\n imageVersion\n pid"
    echo -e "Optional parameters:\n accessPortal\n configServer\n notificationServer\n"
}

# Patching mainTemplate.
function patchMainTemplate() {
    if [ -z ${accessPortal} ]; then
        jq ".variables.hostSetup.accessPortal = \"${accessPortal}\"" ${MAIN_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${MAIN_TEMPLATE}
    fi

    if [ -z ${configServer} ]; then
        jq ".variables.hostSetup.configServer = \"${configServer}\"" ${MAIN_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${MAIN_TEMPLATE}
    fi

    if [ -z ${notificationServer} ]; then
        jq ".variables.hostSetup.notificationServer = \"${notificationServer}\"" ${MAIN_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${MAIN_TEMPLATE}
    fi

    # Removing hostSetup section in case if we not need override it.
    if [ -z ${accessPortal} ] && [ -z ${configServer} ] && [ -z ${notificationServer} ]; then
        jq "del(.variables.hostSetup)" ${MAIN_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${MAIN_TEMPLATE}
    fi

    jq ".variables.imageOffer = \"${imageOffer}\"" ${MAIN_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${MAIN_TEMPLATE}
    jq ".variables.imagePublisher = \"${imagePublisher}\"" ${MAIN_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${MAIN_TEMPLATE}
    jq ".variables.imageSku = \"${imageSku}\"" ${MAIN_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${MAIN_TEMPLATE}
    jq ".variables.imageVersion = \"${imageVersion}\"" ${MAIN_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${MAIN_TEMPLATE}

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

if [ -z ${imageOffer} ] || [ -z ${imagePublisher} ] || [ -z ${imageSku} ] || [ -z ${imageVersion} ] || [ -z ${pid} ]; then
    usage
    exit 0
fi

if [ ! -f ${MAIN_TEMPLATE} ]; then
    echo "Can't find file ${MAIN_TEMPLATE}"
    exit 1
fi

patchMainTemplate
archive
