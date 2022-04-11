#!/bin/bash

MAIN_TEMPLATE=main/mainTemplate.json
UI_TEMPLATE=main/createUiDefinition.json

# Main template variables section.
ACCESS_PORTAL_PARAMETER='{"type":"string","metadata":{"description":"Access portal."},"defaultValue":""}'
CONFIG_SERVER_PARAMETER='{"type":"string","metadata":{"description":"Config server."},"defaultValue":""}'
CUSTOM_DATA_PARAMETER='{"type":"string","metadata":{"description":"CustomData for cloudinit."},"defaultValue":""}'
CUSTOM_DATA_VM="[base64(if(empty(parameters('customData')), variables('customData'), parameters('customData')))]"
CUSTOM_DATA_WO_HTTP_PROXY="[concat(variables('cloudConfig'), '  access_portal: ', parameters('accessPortal'), '\n  config_server: ', parameters('configServer'), '\n  notification_server: ', parameters('notificationServer'), '\n  jointoken: ', parameters('jointoken'), '\n')]"
NOTIFICATION_SERVER_PARAMETER='{"type":"string","metadata":{"description":"Notification server."},"defaultValue":""}'
SG_SSH='{"type":"string","defaultValue":"false","allowedValues":["false","true"]}'
SR="[if(equals(parameters('securityGroupSsh'), 'true'), concat(if(equals(parameters('securityGroupBootstrapUi'), 'true'), variables('securityRuleHtps'), json('[]')), variables('securityRuleSsh')), if(equals(parameters('securityGroupBootstrapUi'), 'true'), variables('securityRuleHtps'), json('[]')))]"
SR_SSH='[{"name":"SSH","properties":{"description":"Allow SSH","access":"Allow","destinationAddressPrefix":"*","destinationPortRange":"22","direction":"Inbound","priority":100,"protocol":"Tcp","sourceAddressPrefix":"*","sourcePortRange":"*"}}]'

# UI template variables section.
UI_ACCESS_PORTAL_OUTPUT="[basics('hostSetup').accessPortal]"
UI_CONFIG_SERVER_OUTPUT="[basics('hostSetup').configServer]"
UI_CUSTOM_DATA_FIELD='[{"name":"customData","type":"Microsoft.Common.TextBox","label":"Custom data","toolTip":"Pass Custom Data for cloudinit.","multiLine":true,"constraints":{"required":false,"regex":"(?=.*).{0,100000}","validationMessage":"The Custom data cannot be more than 100000 characters."},"visible":"[equals(basics('"'"'injecting'"'"'), '"'"'Custom Data'"'"')]"}]'
UI_CUSTOM_DATA_OUTPUT="[basics('customData')]"
UI_HOST_SETUP_FIELD='[{"name":"hostSetup","type":"Microsoft.Common.Section","label":"Host setup","elements":[{"name":"accessPortal","type":"Microsoft.Common.TextBox","label":"Access portal","toolTip":"Access portal.","constraints":{"required":false,"regex":"([a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\\.[^\\s]{2,}).{0,1000}","validationMessage":"Insert valid Access portal."},"visible":"true"},{"name":"configServer","type":"Microsoft.Common.TextBox","label":"Config server","toolTip":"Config server.","constraints":{"required":false,"regex":"([a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\\.[^\\s]{2,}).{0,1000}","validationMessage":"Insert valid Config server."},"visible":"true"},{"name":"notificationServer","type":"Microsoft.Common.TextBox","label":"Notification server","toolTip":"Notification server.","constraints":{"required":false,"regex":"([a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\\.[^\\s]{2,}).{0,1000}","validationMessage":"Insert valid Notification server."},"visible":"true"}],"visible":true}]'
UI_JOINTOKEN_VISIBLE="[equals(basics('injecting'), 'Jointoken')]"
UI_INJECTING_FIELD='[{"name":"injecting","type":"Microsoft.Common.OptionsGroup","label":"Injecting","defaultValue":"Jointoken","toolTip":"Choose the type of injection.","constraints":{"allowedValues":[{"label":"Jointoken","value":"Jointoken"},{"label":"Custom Data","value":"Custom Data"}],"required":true},"visible":true}]'
UI_NOTIFICATION_SERVER_OUTPUT="[basics('hostSetup').notificationServer]"
UI_SG_SSH_OPTION='[{"label":"SSH (22)","value":"ssh"}]'
UI_SG_SSH_OUTPUT="[if(contains(steps('vmSettings').securityGroup, 'ssh'), 'true', 'false')]"

function patchMainTemplate() {
    # Adding securityRuleSsh to variables section.
    jq ".variables.securityRuleSsh = ${SR_SSH}" ${MAIN_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${MAIN_TEMPLATE}

    # Adding accessPortal, configServer, customData, notificationServer and securityGroupSsh to parameters section.
    jq ".parameters.accessPortal = ${ACCESS_PORTAL_PARAMETER}" ${MAIN_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${MAIN_TEMPLATE}
    jq ".parameters.configServer = ${CONFIG_SERVER_PARAMETER}" ${MAIN_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${MAIN_TEMPLATE}
    jq ".parameters.customData = ${CUSTOM_DATA_PARAMETER}" ${MAIN_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${MAIN_TEMPLATE}
    jq ".parameters.notificationServer = ${NOTIFICATION_SERVER_PARAMETER}" ${MAIN_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${MAIN_TEMPLATE}
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

    # Adding customData and hostSetup fields.
    jq ".parameters.basics += ${UI_CUSTOM_DATA_FIELD}" ${UI_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${UI_TEMPLATE}
    jq ".parameters.basics += ${UI_HOST_SETUP_FIELD}" ${UI_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${UI_TEMPLATE}

    # Updating visible option for jointoken field.
    jq "( .parameters.basics[] | select(.name == \"jointoken\") ).visible |= \"${UI_JOINTOKEN_VISIBLE}\"" ${UI_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${UI_TEMPLATE}

    # Adding accessPortal, configServer, customData, notificationServer and ecurityGroupSsh to output section.
    jq ".parameters.outputs.accessPortal = \"${UI_ACCESS_PORTAL_OUTPUT}\"" ${UI_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${UI_TEMPLATE}
    jq ".parameters.outputs.configServer = \"${UI_CONFIG_SERVER_OUTPUT}\"" ${UI_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${UI_TEMPLATE}
    jq ".parameters.outputs.customData = \"${UI_CUSTOM_DATA_OUTPUT}\"" ${UI_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${UI_TEMPLATE}
    jq ".parameters.outputs.notificationServer = \"${UI_NOTIFICATION_SERVER_OUTPUT}\"" ${UI_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${UI_TEMPLATE}
    jq ".parameters.outputs.securityGroupSsh = \"${UI_SG_SSH_OUTPUT}\"" ${UI_TEMPLATE} > tmp.$$.json && mv tmp.$$.json ${UI_TEMPLATE}
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

patchMainTemplate
patchUITemplate
