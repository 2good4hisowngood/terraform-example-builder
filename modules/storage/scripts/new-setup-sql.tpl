#   Configure SQL server
# params
$sqlservername = args[0]
$client = args[1]

#############################
# firewall-rules.ps1 - OK 
#Rogelio's notes:
#I have an old script that includes ports TCP 1434, SQL Service Brocker TCP 4022, SQL Browser TCP2382 , 80,443
#############################
Write-host "=======================CALLING SQL FIREWALL RULES MODULE======================="
New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -LocalPort 1433 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "SSRS Reports" -Direction Inbound -LocalPort 8008 -Protocol TCP -Action Allow


#############################
# initializeSQLdisk.ps1 - OK
#############################
Write-host "=======================CALLING INITALIZE SQL DISK MODULE======================="
Get-Disk -number 2|
         Initialize-Disk -PartitionStyle GPT -PassThru |
            New-Volume -FileSystem NTFS -DriveLetter F -FriendlyName 'SQLVMData1'


            
#############################
# SQLImportModule.ps1 -OK
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
# SQLFolderCreation.ps1 - 
#TODO 
#1.ADD SSIS Folder
#2.Folder permissions NT Service\MSSQLSERVER,NT Service\SQLSERVERAGENT 
#3.Usually the SQL Server Agent is disabled. You can add a script to enable it.
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

if ((Test-Path -Path "F:\SQL\$client\SSIS") -eq $false)
{
    New-Item -Path "F:\SQL\$client" -Name "SSIS" -ItemType "directory" -erroraction 'silentlycontinue'
}
Start-Sleep -Second 10;






#############################
# SALogons.ps1
#############################
Write-host "=======================CALLING SA LOGIN AND PASSWORD CHANGE SQL MODULE======================="
$appLogins = @('sa')
$tempholderpass = @()
$saSQL = Get-SqlLogin -ServerInstance "$Clientsql1" -LoginName "$appLogins"
$saSQL.enable()
$saSQL.PasswordPolicyEnforced = 0
$saSQLpassword = $loginDefaultSA
foreach($appLogins in $appLogins)
{
$SATemppassword = $saSQLpassword
$ServerName = "$Clientsql1"
$srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $ServerName
$SQLUser = $srv.Logins | ? {$_.Name -eq "sa"};
$SQLUser.ChangePassword($SATemppassword);
$tempholderpass += ("Username: $appLogins`nPassword: " + $saSQLpassword.toUpper())
}
foreach($tempholderpass in $tempholderpass)
    { 
        $tempholderpass
        "`n"
    }
    $tempholderpass = @()
    $appEnv = $appEnvRetainer

    Start-Sleep -Second 10;

#############################
# sqllogons.ps1
#############################
Write-host "=======================CALLING SQL SA/appLOGID SETUP AND PERMISSIONS SQLLOGONS MODULE======================="
$appEnv = $appEnvRetainer
$index = '1'
function SAroles
{
$server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $Clientsql1
$roleName =@('db_owner'<#,'db_accessadmin','db_securityadmin','MlsUseOnly'#>)
$databasestring = $server.Databases[$Database]
if ($databasestring.Users[$loginSAUser])
{
    $databasestring.Users[$loginSAUser].Drop()
}
$dbUser = New-Object `
-TypeName Microsoft.SqlServer.Management.Smo.User `
-ArgumentList $databasestring, $loginSAUser
$dbUser.Login = $loginName
$dbUser.Create()
   foreach ($roleName in $roleName)
{ 
$dbrole = $databasestring.Roles[$roleName]
$dbrole.AddMember($loginSAUser)
$dbrole.Alter
}
    if ($index -eq '1')
        {        
        $svr = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $Clientsql1
        $svrole = $svr.Roles | where {$_.Name -eq 'securityadmin'}
        $svrole.AddMember($loginSAUser) 
         $Database2 = @('appWork','msdb')
            foreach ($Database2 in $Database2)
                {                
                $roleName2 = 'db_owner'
                $databasestring2 = $server.Databases[$Database2]

                 if ($databasestring2.Users[$loginSAUser])
                        {
                        $databasestring2.Users[$loginSAUser].Drop()
                        }
                $dbUser2 = New-Object `
                -TypeName Microsoft.SqlServer.Management.Smo.User `
                -ArgumentList $databasestring2, $loginSAUser
                $dbUser2.Login = $loginName
                $dbUser2.Create()                
                 $dbrole2 = $databasestring2.Roles[$roleName2]
                 $dbrole2.AddMember($loginSAUser)
                 $dbrole2.Alter                  
             }
    $index = '0'
}
}
function applogroles
{
$server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $Clientsql1
$roleName ='MlsUseOnly'
$databasestring = $server.Databases[$Database]
if ($databasestring.Users[$loginappLogID])
{
    $databasestring.Users[$loginappLogID].Drop()
}
$dbUser = New-Object `
-TypeName Microsoft.SqlServer.Management.Smo.User `
-ArgumentList $databasestring, $loginappLogID
$dbUser.Login = $loginName
$dbUser.Create()
$dbrole = $databasestring.Roles[$roleName]
$dbrole.AddMember($loginappLogID)
$dbrole.Alter
}
function NotificationSAroles
{
$server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $Clientsql1
$roleName =@('db_owner'<#,'db_accessadmin','db_securityadmin','MlsUseOnly'#>)
$databasestring = $server.Databases[$Database]
if ($databasestring.Users[$loginNotificationSA])
{
    $databasestring.Users[$loginNotificationSA].Drop()
}
$dbUser = New-Object `
-TypeName Microsoft.SqlServer.Management.Smo.User `
-ArgumentList $databasestring, $loginNotificationSA
$dbUser.Login = $loginName
$dbUser.Create()

   foreach ($roleName in $roleName)
{ 
$dbrole = $databasestring.Roles[$roleName]
$dbrole.AddMember($loginNotificationSA)
$dbrole.Alter
}
}
   Add-SqlLogin -ServerInstance "$Clientsql1" -LoginName "$loginSAUser" -LoginType "SqlLogin" -DefaultDatabase "master" -enable
   Add-SqlLogin -ServerInstance "$Clientsql1" -LoginName "$loginappLogID" -LoginType "SqlLogin" -DefaultDatabase "master" -enable
   if($notificationsValid -eq 'yes')
   {
        Add-SqlLogin -ServerInstance "$Clientsql1" -LoginName "$loginNotificationSA" -LoginType "SqlLogin" -DefaultDatabase "master" -enable
   }
   foreach ($appEnv in $appEnv)
{ 
    $Database = "$client" + "_app$appEnv"
     SAroles
    applogroles
    if($notificationsValid -eq 'yes')
   {
        NotificationSAroles
   }
}
#changes logins below, then displays them
$appLogins = @("$loginSAUser","$loginappLogID")
#change to += array later
$tempholderpass = @()
foreach($appLogins in $appLogins)
{
    #modifies permissions to allow a connection to sql
        $server = new-object ("Microsoft.SqlServer.Management.Smo.Server") $Clientsql1
        $perm = new-object ('Microsoft.SqlServer.Management.Smo.ServerPermissionSet')
        $perm.ConnectSql = $true
        $Server.Grant($perm, $appLogins)
    $saSQL = Get-SqlLogin -ServerInstance "$Clientsql1" -LoginName "$appLogins"
    $saSQL.enable()
    $saSQL.PasswordPolicyEnforced = 0
    if($appLogins -eq "$loginSAUser")
    {
        $saSQLpassword = $loginSAPassword
    }
    if($appLogins -eq "$loginappLogID")
    {
        $saSQLpassword = $loginappLogIDPassword
    }
    if($appLogins -eq "$loginNotificationSA")
    {
        $saSQLpassword = $loginNotificationPassword
    }
    "`n"
    $saSQL.ChangePassword($saSQLpassword.ToUpper());
    $saSQL.Alter();
    $saSQL.Refresh();
    $saUsername = $saSQL.Name.ToString()
    $tempholderpass += ("Username: $appLogins`nPassword: " + $saSQLpassword.toUpper())
}
foreach($tempholderpass in $tempholderpass)
    { 
        $tempholderpass
        "`n"
    }
    $tempholderpass = @()
    $appEnv = $appEnvRetainer
    Start-Sleep -Second 10;

#############################
# RestartSQLService.ps1
#############################
Write-host "=======================CALLING RESTART SQL MODULE======================="
    #sets the sql auth mode to sql/windows and restarts service
    $sql = [Microsoft.SqlServer.Management.Smo.Server]::new("$Clientsql1")
    $sql.Settings.LoginMode = 'Mixed'
    $sql.Alter()
    Get-Service -Name 'MSSQLSERVER' | Restart-Service -Force

    Start-Sleep -Second 10;

#############################
# SqlWindowsLoginsDBAdmins.ps1
#############################
Write-host "=======================CALLING SQL DBADMINS CREATION MODULE======================="
#To add a domain group to SQL Server, then grant it sysadmin access, use:
$sqlserver = "$Clientsql1"
$group = "$domain\DBAdmins"
[void][Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO")
$server = New-Object Microsoft.SqlServer.Management.Smo.Server $sqlserver
$login = New-Object Microsoft.SqlServer.Management.Smo.Login($sqlserver, $group)
$login.LoginType = "WindowsGroup"
$login.Create()
$sysadmin = $server.Roles["sysadmin"]
$sysadmin.AddMember($group)
New-SmbShare -Name "SQL Files" -Path "F:\SQL" 
Grant-SmbShareAccess -Name "SQL Files" -AccountName "$group" -AccessRight Full -Force

Start-Sleep -Second 10;

#############################
# SQLWindowsLoginClientSSMS.ps1
#############################
Write-host "=======================CALLING SQL CLIENTSSMS MODULE======================="
$appEnv = $appEnvRetainer
#To add a domain group to SQL Server, then grant it sysadmin access, use:
$sqlserver = "$Clientsql1"
$group = ("$domain\$client" + "SSMS")
[void][Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO")
$server = New-Object Microsoft.SqlServer.Management.Smo.Server $sqlserver
$login = New-Object Microsoft.SqlServer.Management.Smo.Login($sqlserver, $group)
$login.LoginType = "WindowsGroup"
$login.Create()
foreach ($appEnv in $appEnv)
{ 
$Database = "$client" + "_app$appEnv"
$query3 = "
USE $Database;
GO
CREATE USER [$group] FROM LOGIN [$group];
EXEC sp_addrolemember 'MlsUseOnly', '$group';
EXEC sp_addrolemember 'db_datareader', '$group';
"
Invoke-Sqlcmd -ServerInstance $Clientsql1 -Database "$Database" -Query "$query3"
}
$appEnv = $appEnvRetainer        

#############################
# SQLWindowsLoginClientSSMS.ps1
#############################
Write-host "=======================CALLING SQL CLIENTSSMS MODULE======================="
$appEnv = $appEnvRetainer
#To add a domain group to SQL Server, then grant it sysadmin access, use:
$sqlserver = "$Clientsql1"
$group = ("$domain\$client" + "SSMS")
[void][Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO")
$server = New-Object Microsoft.SqlServer.Management.Smo.Server $sqlserver
$login = New-Object Microsoft.SqlServer.Management.Smo.Login($sqlserver, $group)
$login.LoginType = "WindowsGroup"
$login.Create()
foreach ($appEnv in $appEnv)
{ 
$Database = "$client" + "_app$appEnv"
$query3 = "
USE $Database;
GO
CREATE USER [$group] FROM LOGIN [$group];
EXEC sp_addrolemember 'MlsUseOnly', '$group';
EXEC sp_addrolemember 'db_datareader', '$group';
"
Invoke-Sqlcmd -ServerInstance $Clientsql1 -Database "$Database" -Query "$query3"
}
$appEnv = $appEnvRetainer

#############################
# SQLWindowsLoginClientSSMS.ps1
#############################
Write-host "=======================CALLING DOMAIN ADMINS MODULE======================="
#To add a domain group to SQL Server, then grant it sysadmin access, use:
$sqlserver = "$Clientsql1"
$group = "$domain\Domain admins"
[void][Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO")
$server = New-Object Microsoft.SqlServer.Management.Smo.Server $sqlserver
$login = New-Object Microsoft.SqlServer.Management.Smo.Login($sqlserver, $group)
$login.LoginType = "WindowsGroup"
$login.Create()
$sysadmin = $server.Roles["sysadmin"]
$sysadmin.AddMember($group)



























#############################
# ReportServerInstall.ps1
#############################
Write-host "=======================CALLING REPORT SERVER INSTALL MODULE======================="
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-Module -Name Az -AllowClobber
Install-Module -Name SqlServer -AllowClobber -Force
Import-Module -Name "SqlServer" -Force
$pidFileLocation = "C:\SQLServerFull\x64\DefaultSetup.ini"
$fileContent = Get-Content $pidFileLocation
$PID1 = $fileContent[3-1] 
$PIDTrue = $PID1 -replace 'PID="' -replace '"'
$PIDTrue
if((Test-Path "C:\SQLReportsInstallTemp") -eq $false)
{
        New-Item -Path "C:\" -Name "SQLReportsInstallTemp" -ItemType "directory" -erroraction 'silentlycontinue'   
}
if ((Test-Path -Path "C:\azcopy\azcopy.exe") -eq $false)
{
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    #Download AzCopy
    Invoke-WebRequest -Uri "https://aka.ms/downloadazcopy-v10-windows" -OutFile AzCopy.zip -UseBasicParsing
    #Expand Archive
    Expand-Archive ./AzCopy.zip ./AzCopy -Force
    #Move AzCopy to the destination you want to store it
    Get-ChildItem ./AzCopy/*/azcopy.exe | Move-Item -Destination "C:\azcopy"
    #Add your AzCopy path to the Windows environment PATH (C:\Users\thmaure\AzCopy in this example), e.g., using PowerShell:
    $userenv = [System.Environment]::GetEnvironmentVariable("Path", "User")
    [System.Environment]::SetEnvironmentVariable("PATH", $userenv + ";C:\azcopy", "User")   
}
    C:\azcopy\azcopy.exe cp "https://ncentralfilestorage.file.core.windows.net/setupfiles/SQLServerReportingServices.exe$SAS" "C:\SQLReportsInstallTemp" --recursive=true
    C:\SQLReportsInstallTemp\SQLServerReportingServices.exe  /quiet /norestart /IAcceptLicenseTerms /PID=$PIDTrue
    Start-Sleep -Second 10;   
    #gets db creation script
    $configset = Get-WmiObject –namespace "root\Microsoft\SqlServer\ReportServer\RS_SSRS\v14\Admin" `
        -class MSReportServer_ConfigurationSetting -ComputerName localhost    
     [string]$dbscript = $configset.GenerateDatabaseCreationScript("ReportServer", 1033, $false).Script
    #applies it using master
    $sql2 = @"
    USE [master]
    go
    $dbscript
"@
invoke-sqlcmd -ServerInstance "$Clientsql1" -Query $sql2
#set permissions to databases
<#
#>
#ssrs report configuration manager
<#
$configset.SetVirtualDirectory("ReportServer", "Reports", 1033)
$configset.ReserveURL("ReportServerWebApp", "http://+:8008", 1033)
#>
#manully run installer
<#check to done, then configure environment folders
#>


            










