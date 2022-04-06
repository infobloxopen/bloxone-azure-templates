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
    echo -e "\nUsage: $0 imageOffer=<imageOffer> imagePublisher=<imagePublisher> imageSku=<imageSku> imageVersion=<imageVersion> trackingId=<trackingId>"
    echo -e "Required parameters:\n imageOffer\n imagePublisher\n imageSku\n imageVersion\n trackingId"
    echo "You can get imageOffer, imagePublisher, imageSku and imageVersion in your virtual machine offer."
    echo "You can get trackingId in your application offer."
}

# Patching mainTemplate.
function patchMainTemplate() {
    jq ".variables.imageOffer = \"${imageOffer}\"" ${MAIN_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${MAIN_TEMPLATE}
    jq ".variables.imagePublisher = \"${imagePublisher}\"" ${MAIN_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${MAIN_TEMPLATE}
    jq ".variables.imageSku = \"${imageSku}\"" ${MAIN_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${MAIN_TEMPLATE}
    jq ".variables.imageVersion = \"${imageVersion}\"" ${MAIN_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${MAIN_TEMPLATE}

    jq ".resources[0].name = \"${trackingId}\"" ${MAIN_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${MAIN_TEMPLATE}
    
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

if [ -z ${imageOffer} ] || [ -z ${imagePublisher} ] || [ -z ${imageSku} ] || [ -z ${imageVersion} ] || [ -z ${trackingId} ]; then
    usage
    exit 0
fi

if [ ! -f ${MAIN_TEMPLATE} ]; then
    echo "Can't find file ${MAIN_TEMPLATE}"
    exit 1
fi

patchMainTemplate
archive
