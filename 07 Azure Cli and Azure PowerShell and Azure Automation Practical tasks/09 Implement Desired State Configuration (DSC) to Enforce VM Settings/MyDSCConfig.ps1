Configuration MyDSCConfig
{
    Node 'devwindowsvm'
    {
        # Install IIS
        WindowsFeature IIS
        {
            Name = 'Web-Server'
            Ensure = 'Present'
        }

        # Ensure config.xml is created with content
        File WebConfigFile
        {
            Ensure = 'Present'
            Type = 'File'
            DestinationPath = 'C:\inetpub\wwwroot\config.xml'
            Contents = @"
<configuration>
  <settings>
    <setting name="ExampleSetting" value="True"/>
  </settings>
</configuration>
"@
        }

        # Ensure IIS service is running
        Service IISService
        {
            Name = 'w3svc'
            State = 'Running'
            StartupType = 'Automatic'
        }
    }
}

# Call the configuration
MyDSCConfig
