# Setup-host.tpl is a template file to be compiled in the terraform process to create the ps1 files that get uploaded to a clients' storage account. 
# Parameters

$storageAccountName = $args[0]
$storageAccountKey  = $args[1]
$domain             = $args[2]
$aad_group_name     = $args[3]
$testdetails = $args[4]




# #this section lets me check if my changes are working - Sean :)
# $testvalue = @"
# $testdetails
# Lines 2-5 below have the first 4 params
# $storageAccountName
# $storageAccountKey
# $domain
# $aad_group_name
# "@

# New-Item -ItemType File -Path "C:/test" -Name "control.txt" -Value $testvalue -Force -ErrorAction Stop


# $hookUrl = ""
# $content = $testvalue
# $payload = [PSCustomObject]@{
#     content = $content
# }
# Invoke-RestMethod -Uri $hookUrl -Method Post -Body ($payload | ConvertTo-Json) -ContentType 'Application/Json'







#   Variables
$computerName = "$storageAccountName.file.core.windows.net"
$identity = "$domain\$aad_group_name"

#fslogix share
$fsxPath = "U:"
$connectTestResult = Test-NetConnection -ComputerName $computerName -Port 445
if ($connectTestResult.TcpTestSucceeded)
{
  net use $fsxPath "\\$computerName\fslogix" /user:"Azure\$storageAccountName" $storageAccountKey
}
else
{
  Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN,   Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
}
if ((Test-Path -Path $fsxPath) -eq $true)
{
    $fsxacl = Get-Acl $fsxPath
    $system = (New-Object System.Security.Principal.SecurityIdentifier('S-1-5-18'));
    $fsxrule = New-Object System.Security.AccessControl.FileSystemAccessRule($system, "FullControl", "ContainerInherit, ObjectInherit", "None","Allow")
    $fsxacl.AddAccessRule($fsxrule)
    $fsxacl.SetOwner($system) #SYSTEM
    $fsxacl| Set-Acl -Path $fsxPath
    $fsxrule = New-Object System.Security.AccessControl.FileSystemAccessRule((New-Object System.Security.Principal.SecurityIdentifier('S-1-3-0')), "FullControl", "ContainerInherit, ObjectInherit", "None","Allow") # CREATOR OWNER
    $fsxacl.AddAccessRule($fsxrule)
    $fsxacl| Set-Acl -Path $fsxPath    
    $fsxrule = New-Object System.Security.AccessControl.FileSystemAccessRule((New-Object System.Security.Principal.SecurityIdentifier('S-1-5-11')), "Modify", "ContainerInherit, ObjectInherit", "None","Allow") # Authenticated Users
    $fsxacl.AddAccessRule($fsxrule)
    $fsxacl| Set-Acl -Path $fsxPath
    $fsxrule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators", "FullControl", "ContainerInherit, ObjectInherit", "None","Allow") # Administrators
    $fsxacl.AddAccessRule($fsxrule)
    $fsxacl| Set-Acl -Path $fsxPath
    $fsxrule = New-Object System.Security.AccessControl.FileSystemAccessRule("Users", "ReadAndExecute", "ContainerInherit, ObjectInherit", "None","Allow") # Users
    $fsxacl.AddAccessRule($fsxrule)
    $fsxacl| Set-Acl -Path $fsxPath  
    $fsxrule = New-Object System.Security.AccessControl.FileSystemAccessRule($identity, "ReadAndExecute", "ContainerInherit, ObjectInherit", "None","Allow")
    $fsxacl.AddAccessRule($fsxrule)
    Set-Acl -Path $fsxPath  -AclObject $fsxacl
    $fsxrule = New-Object System.Security.AccessControl.FileSystemAccessRule($identity, "ListDirectory", "ContainerInherit, ObjectInherit", "None","Allow")
    $fsxacl.AddAccessRule($fsxrule)
    $fsxacl| Set-Acl -Path $fsxPath 
}

#msix share
$msixPath = "I:"
$connectTestResult = Test-NetConnection -ComputerName $computerName -Port 445
if ($connectTestResult.TcpTestSucceeded)
{
  net use $msixPath "\\$computerName\msix" /user:"Azure\$storageAccountName" $storageAccountKey
}
else
{
  Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN,   Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
}
if ((Test-Path -Path $msixPath) -eq $true)
{
    $msixacl = Get-Acl $msixPath
    $system = (New-Object System.Security.Principal.SecurityIdentifier('S-1-5-18'));
    $msixrule = New-Object System.Security.AccessControl.FileSystemAccessRule($system, "FullControl", "ContainerInherit, ObjectInherit", "None","Allow")
    $msixacl.AddAccessRule($msixrule)
    $msixacl.SetOwner($system) #SYSTEM
    $msixacl| Set-Acl -Path $msixPath
    $msixrule = New-Object System.Security.AccessControl.FileSystemAccessRule((New-Object System.Security.Principal.SecurityIdentifier('S-1-3-0')), "FullControl", "ContainerInherit, ObjectInherit", "None","Allow") # CREATOR OWNER
    $msixacl.AddAccessRule($msixrule)
    $msixacl| Set-Acl -Path $msixPath    
    $msixrule = New-Object System.Security.AccessControl.FileSystemAccessRule((New-Object System.Security.Principal.SecurityIdentifier('S-1-5-11')), "Modify", "ContainerInherit, ObjectInherit", "None","Allow") # Authenticated Users
    $msixacl.AddAccessRule($msixrule)
    $msixacl| Set-Acl -Path $msixPath
    $msixrule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators", "FullControl", "ContainerInherit, ObjectInherit", "None","Allow") # Administrators
    $msixacl.AddAccessRule($msixrule)
    $msixacl| Set-Acl -Path $msixPath
    $msixrule = New-Object System.Security.AccessControl.FileSystemAccessRule("Users", "ReadAndExecute", "ContainerInherit, ObjectInherit", "None","Allow") # Users
    $msixacl.AddAccessRule($msixrule)
    $msixacl| Set-Acl -Path $msixPath  
    $msixrule = New-Object System.Security.AccessControl.FileSystemAccessRule($identity, "ReadAndExecute", "ContainerInherit, ObjectInherit", "None","Allow")
    $msixacl.AddAccessRule($msixrule)
    Set-Acl -Path $msixPath  -AclObject $msixacl
    $msixrule = New-Object System.Security.AccessControl.FileSystemAccessRule($identity, "ListDirectory", "ContainerInherit, ObjectInherit", "None","Allow")
    $msixacl.AddAccessRule($msixrule)
    $msixacl| Set-Acl -Path $msixPath 
}
else
{
    Write-Host "Path $msixPath not found"
}


#   fslogix_install_and_configure.ps1
# Create folder and download installer to destination folder, then unzip file, then install
# variables
$url = "https://aka.ms/fslogix/download"
$destination = "C:\\Program Files\\FS Logix"
$zip = "FSLogix_Apps_2.9.7979.62170.zip"
$installersubfolder = "x64\Release"
$installer = "FSLogixAppsSetup.exe"
# Start-BitsTransfer -Source $url -Destination $dest 
# $FSLogixShare This should be fed in via terraform 


#check if destination folder exists, if not create it
if (!(test-path $destination)) {
    mkdir $destination
}
# download file
Invoke-WebRequest -o $destination$zip $url
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

# Registry key reference: https://docs.microsoft.com/en-us/fslogix/profile-container-configuration-reference
New-Item -Path HKLM:\SOFTWARE\FSLogix\Profiles
write-host "[+] FSLogix Profiles Enabled"
$registrypath="HKLM:\SOFTWARE\FSLogix\Profiles"
$name="Enabled"
$value=1
# 0: Profile Containers disabled. 1: Profile Containers enabled
SetRegistryHardening ($registrypath,$name,$value)

write-host "[+] FSLogix Profiles VHDLocations"
$registrypath="HKLM:\SOFTWARE\FSLogix\Profiles"
$name="VHDLocations"
$value="\\$storageAccountName.file.core.windows.net\fslogix"
# Data values and use A list of file system locations to search for the user's profile VHD(X) file. If one isn't found, 
# one will be created in the first listed location. If the VHD path doesn't exist, it will be created before it checks 
# if a VHD(X) exists in the path. These values can contain variables that will be resolved. Supported variables are 
# %username%, %userdomain%, %sid%, %osmajor%, %osminor%, %osbuild%, %osservicepack%, %profileversion%, and any environment 
# variable available at time of use. When specified as a REG_SZ value, multiple locations can be separated with a semi-colon.
SetRegistryHardening ($registrypath,$name,$value)

write-host "[+] FSLogix Profiles VHDLocations"
$registrypath="HKLM:\SOFTWARE\FSLogix\Profiles"
$name="DeleteLocalProfileWhenVHDShouldApply"
$value="1"
# 0: no deletion. 1: delete local profile if exists and matches the profile being loaded from VHD.
SetRegistryHardening ($registrypath,$name,$value)

#########################
# Begin-Section | Create scheduled task to load drives on boot
#########################

$scriptdir = "C:\tools\scripts"
$scriptname = "map_drives.ps1"
$scriptpath = "$scriptdir\$scriptname"
$taskname = "Map SYSTEM Drives"
$admin_group = "$domain\HostingAdmins" # variable replacement in terraform for the domain name


$scriptcontent = @"
`$computerName = "$storageAccountName.file.core.windows.net"
`$connectTestResult = Test-NetConnection -ComputerName `$computerName -Port 445
if (`$connectTestResult.TcpTestSucceeded) {
  # fslogix share
  #if (-not (Test-Path -Path "U:")) {
  #  net use "U:" "\\`$computerName\fslogix" /user:"Azure\$storageAccountName" $storageAccountKey
  #}

  # msix share
  `$msixPath = "I:"
  if (-not (Test-Path -Path `$msixPath)) {
    net use `$msixPath "\\`$computerName\msix" /user:"Azure\$storageAccountName" $storageAccountKey
  } 
} else {
  Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN,   Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
}
"@

# Create a new task action
$taskAction = New-ScheduledTaskAction `
    -Execute 'powershell.exe' `
    -Argument "-File $scriptpath"
# Create a new trigger (At Startup)
$taskTrigger = New-ScheduledTaskTrigger -AtStartup
# The name of your scheduled task.
$taskName = "System drive mapping"
# Describe the scheduled task.
$description = "Confirm drives mapped for system."
# Get CIM for SYSTEM user
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
# Register the scheduled task
$createTask = Register-ScheduledTask `
    -TaskName $taskName `
    -Action $taskAction `
    -Trigger $taskTrigger `
    -Description $description `
    -Principal $principal


#   Check if the script exists, if not create it.

if (-not(Test-Path $scriptpath)) {
    try {
        New-Item -ItemType File -Path $scriptdir -Name $scriptname -Value $scriptcontent -Force -ErrorAction Stop
        Write-Host "The file $scriptname was created"

        $acl = Get-Acl -Path $scriptdir
        $acl.SetAccessRuleProtection($true,$true)
        $acl | Set-Acl $scriptdir 

       # Remove rules for local users
       $rules = $acl.access | Where-Object {
         (-not $_.IsInherited) -and
         $_.IdentityReference -like "$env:computername\Users"
        }
        ForEach($rule in $rules) {
          $acl.RemoveAccessRule($rule) | Out-Null
        }
        
        $rules = $acl.access | Where-Object {
          (-not $_.IsInherited) -and
          $_.IdentityReference -like "Authenticated Users"
        }
        ForEach($rule in $rules) {
          $acl.RemoveAccessRule($rule) | Out-Null
        }
        
        Set-ACL -Path $scriptdir -AclObject $acl
        
        $permission  = "BUILTIN\Administrators","FullControl", "ContainerInherit,ObjectInherit","None","Allow"
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
        $acl.SetAccessRule($rule)
        
        Set-Acl $scriptdir $acl

        Write-Verbose "Inheritance disabled and permissions removed from [$scriptdir]"        
    }
    catch {
        Write-Host "The file $scriptname could not be created, or permissions could not be set"
        throw $_.Exception.Message
        #exit 1
    }
}
    else {
        Write-Host "Cannot create $scriptname, because a file with that name already exists"
    }


    #   Check if the task exists, if not create it.

if (-not(Get-ScheduledTask -TaskName $taskname)) {
    try {
        New-ScheduledTask -TaskName $taskname -Action $taskAction -Trigger $taskTrigger -Principal $admin_group -Description $description
        Write-Host "Task $taskname was created"
        
    }
    catch {
        Write-Host "Task $taskname could not be created"
        throw $_.Exception.Message
        #exit 1
    }
}
    else {
        Write-Host "Cannot create task $taskname, because a task with that name already exists"
    }

#########################
# End-Section | Create scheduled task to load drives on boot
#########################






#########################
# Begin-Section | Map a client's drives by inserting a script into the startup folder
#########################
#   Map a client's drives by inserting a script into the startup folder. 
#   When the user logs in, it should run this script and map their drives.
#   Variables
$storageAccountName = "$storageAccountName"
$storageAccountKey = "$storageAccountKey"
$scriptdir = "c:\scripts"
$startpath = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"
$scriptname = "step1.ps1"
$scriptpath = "$scriptdir\$scriptname"

#   Script to be inserted
#   Variables are replaced during new-item creation
$scriptcontent = @"
# if ((Test-Path -Path "I:") -ne `$true) {
#   net use I: \\$storageAccountName.file.core.windows.net\msix /persistent:yes
# }
# if ((Test-Path -Path "U:") -ne `$true) {
#   net use U: \\$storageAccountName.file.core.windows.net\fslogix /persistent:yes
# }
if ((Test-Path -Path "R:") -ne `$true) {
  net use "R:" \\$storageAccountName.file.core.windows.net\reports /persistent:yes
}
"@

#   Insert Script to folder
if (-not(Test-Path $scriptpath)) {
    try {
        New-Item -ItemType File -Path $scriptdir -Name $scriptname -Value $scriptcontent -Force -ErrorAction Stop
        Write-Host "The file $scriptname was created"
    }
    catch {
        Write-Host "The file $scriptname could not be created, a file with that name may already exist"
        throw $_.Exception.Message
        #exit 1
    }
}
  

# Set file to hidden
if ((Test-Path $scriptpath)) {
    try {
        Get-ChildItem -path $scriptdir -Recurse -Force | foreach {$_.attributes = "Hidden"}
    }
    catch {
            Write-Host "Cannot hide files"
            throw $_.Exception.Message
    }
}

# Create Shortcut in startup folder
$shell = New-Object -COM WScript.Shell
$AppPath = '"step1.ps1"'
$AppFullPath = '"c:\scripts\step1.ps1"'
$cmd = "C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe"
$cmdargs = "-WindowStyle Hidden -NoLogo -NonInteractive -InputFormat None -NoProfile -ExecutionPolicy Bypass -File $AppFullPath"
$DesktopShortcut = $shell.CreateShortcut('C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\step1.lnk')
$DesktopShortcut.TargetPath = $cmd
$DesktopShortcut.Arguments = $cmdargs
$DesktopShortcut.Save()

#########################
# End-Section | Map a client's drives by inserting a script into the startup folder
#########################

#########################
# Begin-Section | Install MICR font
#########################
# Copy-Item "C:\TEMP\e13bscr.ttf" "C:\Windows\Fonts"
# New-ItemProperty -Name "ChequeScribe Screen MICR" -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -PropertyType string -Value "e13bscr.ttf"

# delete installation file reminents
# rm C:\TEMP\e13bscr.ttf
#########################
# End-Section | Install MICR font
#########################



# # This calls the next script
# ./example_script.ps1