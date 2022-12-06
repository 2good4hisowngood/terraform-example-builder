Enable-NetFirewallRule -DisplayName "Windows Management Instrumentation (DCOM-In)"
Enable-NetFirewallRule -DisplayName "Windows Management Instrumentation (WMI-In)"

#############################
# tentacle.ps1
#############################
$download_url = "https://octopus.com/downloads/latest/WindowsX64/OctopusTentacle"
$download_file = "C:\Octopus\OctopusTentacle.msi"

#create file to replace
New-Item -Path $download_file -ItemType File -Force

Invoke-WebRequest -Uri $download_url -OutFile $download_file

msiexec /i $download_file /quiet


cd "C:\Program Files\Octopus Deploy\Tentacle"
$env:Path += ";C:\Program Files\Octopus Deploy\Tentacle"

Start-Sleep -Seconds 60

.\Tentacle.exe create-instance --instance "Tentacle" --config "C:\Octopus\Tentacle.config" --console
.\Tentacle.exe new-certificate --instance "Tentacle" --if-blank --console
.\Tentacle.exe configure --instance "Tentacle" --reset-trust --console
.\Tentacle.exe configure --instance "Tentacle" --home "C:\Octopus" --app "C:\Octopus\Applications" --noListen "True" --console
.\Tentacle.exe register-with --instance "Tentacle" --server "#{octo_url}" --apiKey "#{apikeys.octopus}" --comms-style "TentacleActive" --server-comms-port "10943" --force --environment "#{Octopus.Environment.Name}" --role "app_web" --console --space "app"
.\Tentacle.exe service --instance "Tentacle" --install --start --console