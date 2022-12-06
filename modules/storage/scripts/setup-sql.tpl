# Setup-sql.tpl is a template file to be compiled in the terraform process to create the ps1 files that get uploaded to a clients' storage account. 

#   Variables
$client = $args[1]
$smtp_key = $args[2]

#############################
# firewall-rules.ps1
#############################
Write-host "=======================CALLING SQL FIREWALL RULES MODULE======================="
New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -LocalPort 1433 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "SSRS Reports" -Direction Inbound -LocalPort 8008 -Protocol TCP -Action Allow


# #############################
# # initializeSQLdisk.ps1
# #############################
# Write-host "=======================CALLING INITALIZE SQL DISK MODULE======================="
# Get-Disk -number 2|
#          Initialize-Disk -PartitionStyle GPT -PassThru |
#             New-Volume -FileSystem NTFS -DriveLetter F -FriendlyName 'SQLVMData1'


            
#############################
# SQLImportModule.ps1
#############################
Write-host "=======================CALLING SQL IMPORT MODULES MODULE======================="
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name SqlServer -AllowClobber -Force
Install-Module -Name az -AllowClobber -Force
Import-Module -Name "SqlServer" -Force


Start-Sleep -Second 10;
Start-Sleep -Second 10;


            
#############################
# SQLFolderCreation.ps1
#############################
Write-host "=======================CALLING SQL FOLDER CREATION MODULE======================="
#creates client folder directories
if ((Test-Path -Path "F:\SQL") -eq $false)
{
    New-Item -Path "F:\" -Name "SQL" -ItemType "directory" -erroraction 'silentlycontinue'
}
if ((Test-Path -Path "F:\SQL\$client") -eq $false)
{
    New-Item -Path "F:\SQL" -Name "$client" -ItemType "directory" -erroraction 'silentlycontinue'
}

if ((Test-Path -Path "F:\SQL\$client\databases") -eq $false)
{
    New-Item -Path "F:\SQL\$client" -Name "databases" -ItemType "directory" -erroraction 'silentlycontinue'
}
if ((Test-Path -Path "F:\SQL\$client\backups") -eq $false)
{
    New-Item -Path "F:\SQL\$client" -Name "backups" -ItemType "directory" -erroraction 'silentlycontinue'
}

#############################
# tentacle.ps1
#############################


$download_url = "https://octopus.com/downloads/latest/WindowsX64/OctopusTentacle"
$download_file = "C:\Octopus\OctopusTentacle.msi"

#create file to replace
New-Item -Path $download_file -ItemType File -Force

Invoke-WebRequest -Uri $download_url -OutFile $download_file

msiexec /i $download_file /quiet /norestart


cd "C:\Program Files\Octopus Deploy\Tentacle"
$env:Path += ";C:\Program Files\Octopus Deploy\Tentacle"

Start-Sleep -Seconds 60

.\Tentacle.exe create-instance --instance "Tentacle" --config "C:\Octopus\Tentacle.config" --console
.\Tentacle.exe new-certificate --instance "Tentacle" --if-blank --console
.\Tentacle.exe configure --instance "Tentacle" --reset-trust --console
.\Tentacle.exe configure --instance "Tentacle" --home "C:\Octopus" --app "C:\Octopus\Applications" --noListen "True" --console
.\Tentacle.exe register-with --instance "Tentacle" --server "#{octo_url}" --apiKey "#{apikeys.octopus}" --comms-style "TentacleActive" --server-comms-port "10943" --force --environment "#{Octopus.Environment.Name}" --role "app_db" --console --space "app"
.\Tentacle.exe service --instance "Tentacle" --install --start --console