configuration ${dsc_name} 
{
    param ($ApiKey, $OctopusServerUrl, $Environments, $Roles, $ListenPort, $Space)
    Import-DscResource -Module OctopusDSC

    Node "localhost"
    {
        cTentacleAgent OctopusTentacle
        {
            Ensure = "Present"
            State = "Started"

            # Tentacle instance name. Leave it as 'Tentacle' unless you have more
            # than one instance
            Name = "Tentacle"

            # Defaults to <MachineName>_<InstanceName> unless overridden
            # DisplayName = "My Tentacle"

            # Required parameters. See full properties list below
            ApiKey = "${ApiKey}"
            OctopusServerUrl = "${OctopusServerUrl}"   
            Environments = "${Environments}"
            Roles = "avd-sql, app-db"
            Space = "${Space}"

            # How Tentacle will communicate with the server
            CommunicationMode = "Poll"
            ServerPort = 10943

            # Where deployed applications will be installed by Octopus
            DefaultApplicationDirectory = "C:\Applications"

            # Where Octopus should store its working files, logs, packages etc
            TentacleHomeDirectory = "C:\Octopus"
        }
    }
} 