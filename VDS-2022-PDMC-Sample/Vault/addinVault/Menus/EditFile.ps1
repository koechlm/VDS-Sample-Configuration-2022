
$vaultContext.ForceRefresh = $true
$fileId=$vaultContext.CurrentSelectionSet[0].Id
$dialog = $dsCommands.GetEditDialog($fileId)
if ($IsOfficeClient)
{
	# *ComponentUpgradeEveryRelease-Client*
	$xamlFile = New-Object CreateObject.WPF.XamlFile "FileOffice.xaml", "C:\ProgramData\Autodesk\Vault 2022\Extensions\DataStandard\Vault\Configuration\FileOffice.xaml"
	$dialog.XamlFile = $xamlFile
}
$dialog.Execute()

