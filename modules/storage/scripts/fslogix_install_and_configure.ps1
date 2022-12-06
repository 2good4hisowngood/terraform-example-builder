

# Create folder and download installer to destination folder, then unzip file, then install
# variables
New-Item -ItemType Directory -Force -Path "C:\\Program Files\\FS Logix"
$url = "https://aka.ms/fslogix/download"
$dest = "C:\\Program Files\\FS Logix"
$zip = "FSLogix_Apps_2.9.7979.62170.zip"
$installersubfolder = "x64\Release"
$installer = "FSLogixAppsSetup.exe"
$args = "/quiet","/norestart"
Start-BitsTransfer -Source $url -Destination $dest\$zip
Expand-Archive -LiteralPath $dest\$zip -DestinationPath $dest\
start-process -filepath "$dest\x64\Release\FSLogixAppsSetup.exe" -argumentlist $args

#check if destination folder exists, if not create it
if (!(test-path $destination)) {
    mkdir $destination
}
# download file
curl -o $destination$zip $url
#unzip file
Expand-Archive $destination$zip -d $destination
#install using /install command
start-process -filepath $destination\\$installersubfolder\$installer /quiet
#create registry keys
function SetRegistryHardening()
{
	If (!(Test-Path $registrypath))
		{
			Write-Host "creting new item..."
			New-Item -Path $registrypath -Force | out-null
			New-ItemProperty -Path $registrypath -Name $name -Value $value | out-null
		}
Else
		{
			New-ItemProperty -Path $registrypath -Name $name -Value $value -Force | out-null
		}
}

New-Item -Path HKLM:\SOFTWARE\FSLogix\Profiles
write-host "[+] FSLogix Profiles Enabled"
$registrypath="HKLM:\SOFTWARE\FSLogix\Profiles"
$name="Enabled"
$value=1
SetRegistryHardening ($registrypath,$name,$value)

write-host "[+] FSLogix Profiles VHDLocations"
$registrypath="HKLM:\SOFTWARE\FSLogix\Profiles"
$name="VHDLocations"
$value="\\${azurerm_storage_account.storage.name}.file.core.usgovcloudapi.net\fslogix"
SetRegistryHardening ($registrypath,$name,$value)

write-host "[+] Delete Local Profile When VHD Should Apply"
$registrypath="HKLM:\SOFTWARE\FSLogix\Profiles"
$name="DeleteLocalProfileWhenVHDShouldApply"
$value="1"
SetRegistryHardening ($registrypath,$name,$value)