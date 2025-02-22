Configuration MyDSCConfig
{
    # Define the node (target machine)
    Node 'devMyWinVM'
    {
        # Ensure Web-Server (IIS) feature is installed
        WindowsFeature IIS
        {
            Name = 'Web-Server'
            Ensure = 'Present'
        }

    }
}

# Call the configuration
MyDSCConfig
