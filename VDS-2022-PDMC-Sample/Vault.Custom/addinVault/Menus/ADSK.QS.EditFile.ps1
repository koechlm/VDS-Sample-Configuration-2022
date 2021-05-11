
$vaultContext.ForceRefresh = $true
$fileId=$vaultContext.CurrentSelectionSet[0].Id
$dialog = $dsCommands.GetEditDialog($fileId)
#override the default dialog file assigned
if ($_IsOfficeClient)
{
	$xamlFile = New-Object CreateObject.WPF.XamlFile "Adsk.QS.FileOffice.xaml", "C:\ProgramData\Autodesk\Vault 2022\Extensions\DataStandard\Vault.Custom\Configuration\Adsk.QS.FileOffice.xaml"
	$dialog.XamlFile = $xamlFile
}
else
{
	$xamlFile = New-Object CreateObject.WPF.XamlFile "ADSK.QS.File.xaml", "C:\ProgramData\Autodesk\Vault 2022\Extensions\DataStandard\Vault.Custom\Configuration\ADSK.QS.File.xaml"
	$dialog.XamlFile = $xamlFile
}
$dialog.Execute()

