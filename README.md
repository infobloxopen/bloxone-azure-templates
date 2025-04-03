# Bloxone Azure Templates

## Getting Started

To create zip archive use archive.sh script from utils directory:
```
$ utils/archive.sh accessPortal="" configServer="" notificationServer="" pid=""
```

Basically, this repo bloxone-azure-templates(https://github.com/infobloxopen/bloxone-azure-templates) which is used to provide a template for customer of Infoblox, while deploying the VM.  

To do this or modify the template or UI experience we need to do changes or modify the code in two .json files mainly createUiDefinition.json and mainTemplate.json, and maybe other files based on the requirement. 

In the context of Azure Managed Applications, createUiDefinition.json defines the user interface for creating the application, while mainTemplate.json specifies the Azure resources to be deployed.  

Here's a more detailed breakdown: 

createUiDefinition.json: 
This file defines the user interface elements (like text boxes, drop-downs, etc.) that users see in the Azure portal when creating a managed application. It allows publishers to customize the experience and guide users on how to provide input for parameters needed during deployment.  

mainTemplate.json: 
This file is a standard Azure Resource Manager (ARM) template that specifies the resources to be deployed when the managed application is created. It defines things like web apps, databases, storage accounts, and virtual machines, and is no different than a regular ARM template.  

In essence: 
createUiDefinition.json: focuses on the user experience of creating the application. 
mainTemplate.json: focuses on the deployment of resources when the application is created. 

In this, we have added option for Availability zone, where customer can choose the availability zone and how many zones while deploying the VM. These are the supported regions - https://learn.microsoft.com/en-us/azure/reliability/regions-list 

When you don't select any while launching a VM with the Azure-selected zone option, Azure automatically selects the best availability zone for your VM based on current capacity and performance metrics. This helps to optimize the placement of your VM without requiring you to manually choose a specific zone. 

Here’s how it works: 

Automatic Zone Selection: 
Azure evaluates the available zones within the selected region and places your VM in the zone that offers the best performance and reliability at the time of deployment 

Simplified Deployment: 
You don't need to worry about selecting the zone yourself. This can be particularly useful if you're deploying multiple VMs and want to ensure they are distributed across different zones for redundancy 

Portal Configuration: 
In the Azure portal, you can select the Azure-selected zone option during the VM creation process. The availability zone selection will be grayed out, indicating that Azure will handle the zone placement 


Initially do changes in CretaeUidefinition.json file, then Go to -> Create UI Definition Sandbox(https://portal.azure.com/?feature.customPortal=false#view/Microsoft_Azure_CreateUIDef/SandboxBlade) - Microsoft Azure and paste the json script & check the preview, once you are good with preview, save it. Below is the reference how it looks. 

When availability zone supports for example: East US 

Create UI Definition Sandbox 

!Screenshot from 2025-03-24 15:53:54

When availability zone doesn't support for example: Australia Central 

Create UI Definition Sandbox 
 
!Screenshot from 2025-03-24 16:02:46

Then modify mainTemplate.json accordingly and Go to -> Test UI -> Build your own template -> paste the json content which you have modified -> save to preview 

!Screenshot from 2025-03-26 09:37:00

Use offerid -> infoblox-bloxone-34 & image version -> 3.4.1 - This can be checked with the team internally because this may change sometime. 

And check for final preview, if it is good then proceed for Next. Below is reference. 

When it is success, it'll show Create option like below, here artifacts location we need to provide for manual testing purpose only. 

!Screenshot from 2025-03-26 10:50:04

Use this link for artifacts location -> https://raw.githubusercontent.com/smallu-infoblox/bloxone-azure-templates/refs/heads/main/main/ 

Provide the raw github link to access these files. Make sure both the files are in one location in git. 

For other parameters, provide details correctly there shouldn't be any conflict like if you're providing existing storage account name then give existing and existing storage account name or new and unique storage account name. 

Other way is, in artifacts location you can put all the content from git like above in Azure storage and provide storage-container link along with sas token. 

And when you click on Create and Deployment is success then it shows like below. 

!Screenshot from 2025-03-26 11:26:26

Once this is done, you can click on VM name, check its details and verify it. 

!Screenshot from 2025-03-26 11:30:01

The above process is deploying a regular VM without availability zone 

Below deployed a VM with Zone 1 

!Screenshot from 2025-04-03 08:17:33

Below deployed a VM with Zone 2 

!Screenshot from 2025-04-03 08:19:18

Here, I have tried deploying a VM with OS disk size of 120GB, below is reference. 

!Screenshot from 2025-04-03 08:23:39
 

So, basically createUiDefinition.json file is only a UI interface for viewing purpose. But mainTemplate.json file is something which takes the parameters behind and deploy a VM based on these values, along with other files in nested deployments. 



 
