# terraform-example-builder
This repo is an example of how to build a builder pattern repository


Here's the instructions for Entra joined envs: [Store FSLogix profile containers on Azure Files and Microsoft Entra ID - FSLogix | Microsoft Learn](https://learn.microsoft.com/en-us/fslogix/how-to-configure-profile-container-azure-files-active-directory?context=/azure/virtual-desktop/context/context)

Create share for fslogix: https://github.com/2good4hisowngood/terraform-example-builder/blob/c988f0a493cb7e60ace60d7fa5d34f0fd49e415d/modules/storage/storage.tf#L57C1-L61C2
Join storage account to domain: https://github.com/2good4hisowngood/terraform-example-builder/blob/c988f0a493cb7e60ace60d7fa5d34f0fd49e415d/modules/storage/storage.tf#L32C1-L34C4 
Assign RBAC to client users: https://github.com/2good4hisowngood/terraform-example-builder/blob/c988f0a493cb7e60ace60d7fa5d34f0fd49e415d/modules/client_iam/iam_rbac.tf#L8-L22
Connect session hosts to fslogix shares with ntfs permissions: https://github.com/2good4hisowngood/terraform-example-builder/blob/c988f0a493cb7e60ace60d7fa5d34f0fd49e415d/modules/storage/scripts/setup-host.tpl#L39C1-L80
Configure host to use fslogix profiles: https://github.com/2good4hisowngood/terraform-example-builder/blob/c988f0a493cb7e60ace60d7fa5d34f0fd49e415d/modules/storage/scripts/setup-host.tpl#L163C1-L175C61
