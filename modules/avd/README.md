# Virtual Machines

## Avd hosts

### avd tags
count = the instance number of a given app host vm to easily enable identification for terraform redeploy and other workbook activities. 

## Applying custom scripts to a vm
To apply custom scripts to a vm such that they install on creation, you will be using the virtual machine extension resource. This resource is associated with a server by the virtual_machine_id. 

# Storing your custom scripts
Rather than applying each script to the resource inside of a resource or custom data configuration, you can store it in a centralized storage account and reference it from there. 

# CustomScriptExtension
"CustomScriptExtension" is the type of azure_virtual_machine_extension used to apply PowerShell scripts on VM creation. 

This allows the VMs to be replacable with a terraform apply. 