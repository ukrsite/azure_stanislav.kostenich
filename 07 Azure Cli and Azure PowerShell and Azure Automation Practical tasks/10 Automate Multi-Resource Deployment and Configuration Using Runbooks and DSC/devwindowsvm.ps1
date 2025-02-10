$grp="StanislavKostenich"
$automationAccount="devMyAutomationAccount202502"


echo "IMPORT THE CONFIGURATION"
Import-AzAutomationDscConfiguration -Published -ResourceGroupName $grp -SourcePath ./MyDSCConfig.ps1 -Force -AutomationAccountName $automationAccount
