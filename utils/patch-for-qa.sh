#!/bin/bash

MAIN_TEMPLATE=main/mainTemplate.json
UI_TEMPLATE=main/createUiDefinition.json

CUSTOM_DATA_PARAMETER='{"type":"string","metadata":{"description":"CustomData for cloudinit."},"defaultValue":""}'
CUSTOM_DATA_VM="[base64(if(empty(parameters('customData')), variables('customData'), parameters('customData')))]"
CUSTOM_DATA_WO_HTTP_PROXY="[concat(variables('cloudConfig'), '  access_portal: ', variables('hostSetup').accessPortal, '\n  config_server: ', variables('hostSetup').configServer, '\n  notification_server: ', variables('hostSetup').notificationServer, '\n')]"

SG_SSH='{"type":"string","defaultValue":"false","allowedValues":["false","true"]}'
SR="[if(equals(parameters('securityGroupSsh'), 'true'), concat(if(equals(parameters('securityGroupBootstrapUi'), 'true'), variables('securityRuleHtps'), json('[]')), variables('securityRuleSsh')), if(equals(parameters('securityGroupBootstrapUi'), 'true'), variables('securityRuleHtps'), json('[]')))]"
SR_SSH='[{"name":"SSH","properties":{"description":"Allow SSH","access":"Allow","destinationAddressPrefix":"*","destinationPortRange":"22","direction":"Inbound","priority":100,"protocol":"Tcp","sourceAddressPrefix":"*","sourcePortRange":"*"}}]'

UI_CUSTOM_DATA_FIELD='[{"name":"customData","type":"Microsoft.Common.TextBox","label":"Custom data","toolTip":"Pass Custom Data for cloudinit.","multiLine":true,"constraints":{"required":false,"regex":"(?=.*).{0,100000}","validationMessage":"The Custom data cannot be more than 100000 characters."},"visible":"[equals(basics('"'"'injecting'"'"'), '"'"'Custom Data'"'"')]"}]'
UI_CUSTOM_DATA_OUTPUT="[basics('customData')]"
UI_JOINTOKEN_VISIBLE="[equals(basics('injecting'), 'Jointoken')]"
UI_INJECTING_FIELD='[{"name":"injecting","type":"Microsoft.Common.OptionsGroup","label":"Injecting","defaultValue":"Jointoken","toolTip":"Choose the type of injection.","constraints":{"allowedValues":[{"label":"Jointoken","value":"Jointoken"},{"label":"Custom Data","value":"Custom Data"}],"required":true},"visible":true}]'

UI_SG_SSH_OPTION='[{"label":"SSH (22)","value":"ssh"}]'
UI_SG_SSH_OUTPUT="[if(contains(steps('vmSettings').securityGroup, 'ssh'), 'true', 'false')]"

function patchMainTemplate() {
    # Adding accessPortal, configServer, notificationServer, securityRuleSsh to variables section.
    jq ".variables.hostSetup.accessPortal = \"${accessPortal}\"" ${MAIN_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${MAIN_TEMPLATE}
    jq ".variables.hostSetup.configServer = \"${configServer}\"" ${MAIN_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${MAIN_TEMPLATE}
    jq ".variables.hostSetup.notificationServer = \"${notificationServer}\"" ${MAIN_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${MAIN_TEMPLATE}
    jq ".variables.securityRuleSsh = ${SR_SSH}" ${MAIN_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${MAIN_TEMPLATE}

    # Adding customData, securityGroupSsh to parameters section.
    jq ".parameters.customData = ${CUSTOM_DATA_PARAMETER}" ${MAIN_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${MAIN_TEMPLATE}
    jq ".parameters.securityGroupSsh = ${SG_SSH}" ${MAIN_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${MAIN_TEMPLATE}

    # Updating customDataWithoutHttpProxy, securityRules variables.
    jq ".variables.customDataWithoutHttpProxy = \"${CUSTOM_DATA_WO_HTTP_PROXY}\"" ${MAIN_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${MAIN_TEMPLATE}
    jq ".variables.securityRules = \"${SR}\"" ${MAIN_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${MAIN_TEMPLATE}

    # Updating customData for VM resource.
    jq "( .resources[] | select(.name == \"SettingUpVirtualMachine\") ).properties.parameters.osProfile.value.customData |= \"${CUSTOM_DATA_VM}\"" ${MAIN_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${MAIN_TEMPLATE}
}

function patchUITemplate() {
    # Adding ssh rule option to securityGroup selectbox.
    jq "( .parameters.steps[0].elements[] | select(.name == \"securityGroup\") ).constraints.allowedValues += ${UI_SG_SSH_OPTION}" ${UI_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${UI_TEMPLATE}
    jq "( .parameters.steps[0].elements[] | select(.name == \"securityGroup\") ).multiselect = \"true\"" ${UI_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${UI_TEMPLATE}

    # Adding injecting radio input.
    jq ".parameters.basics += ${UI_INJECTING_FIELD}" ${UI_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${UI_TEMPLATE}

    # Adding Custom data field.
    jq ".parameters.basics += ${UI_CUSTOM_DATA_FIELD}" ${UI_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${UI_TEMPLATE}

    # Updating visible option for jointoken field.
    jq "( .parameters.basics[] | select(.name == \"jointoken\") ).visible |= \"${UI_JOINTOKEN_VISIBLE}\"" ${UI_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${UI_TEMPLATE}

    # Adding scustomData, ecurityGroupSsh to output section.
    jq ".parameters.outputs.customData = \"${UI_CUSTOM_DATA_OUTPUT}\"" ${UI_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${UI_TEMPLATE}
    jq ".parameters.outputs.securityGroupSsh = \"${UI_SG_SSH_OUTPUT}\"" ${UI_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${UI_TEMPLATE}
}

function usage() {
    echo -e "\nUsage: $0 accessPortal=<accessPortal> configServer=<configServer> notificationServer=<notificationServer>"
    echo -e "Required parameters:\n accessPortal\n configServer\n notificationServer\n"
}

# Determining arguments.
for ARGUMENT in "$@"
do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    KEY_LENGTH=${#KEY}
    VALUE="${ARGUMENT:$KEY_LENGTH+1}"
    export "$KEY"="$VALUE"
done

if [ ! -f ${MAIN_TEMPLATE} ] || [ ! -f ${UI_TEMPLATE} ]; then
    echo "Can't find file ${MAIN_TEMPLATE}"
    exit 1
fi

if [ -z ${accessPortal} ] || [ -z ${configServer} ] || [ -z ${notificationServer} ]; then
    usage
    exit 0
fi

patchMainTemplate
patchUITemplate
