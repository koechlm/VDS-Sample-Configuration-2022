#$vaultContext.ForceRefresh = $true
$selectionSet = $vaultContext.CurrentSelectionSet[0]
$id= $selectionSet.Id
$dialog = $dsCommands.GetCreateCustomObjectDialog($id)

#override the default dialog file assigned
$xamlFile = New-Object CreateObject.WPF.XamlFile "ADSK.QS.CustomObject.xaml", "C:\ProgramData\Autodesk\Vault 2022\Extensions\DataStandard\Vault.Custom\Configuration\ADSK.QS.CustomObject.xaml"
$dialog.XamlFile = $xamlFile

$result = $dialog.Execute()
$dsDiag.Trace($result)

if ($result)
{
	#region create_links
	#differentiate for Custent definitions / categories
	$UIString = mGetUIStrings
	#$CustEntDef = $vault.CustomEntityService.GetAllCustomEntityDefinitions() | Where-Object { $_.DispName -eq $UIString["MSDCE_CO02"]}
	$CustEntCatName = $vault.CategoryService.GetCategoryById($dialog.CurrentEntity.Cat.CatId).Name

	If($CustEntCatName -eq $UIString["MSDCE_CO02"])#Person
	{
		try
		{		
			$companyID = Get-Content $env:TEMP"\mOrganisationId.txt"	
			if($companyID -ne "") { $link1 = $vault.DocumentService.AddLink($companyID,"CUSTENT",$dialog.CurrentEntity.Id,"Organisation->Person") } #Add Person as content to Organisation
		}
		catch
		{
			$dsDiag.Trace("CreateCustomObject.ps1 - AddLink command failed") 
		}
		finally {
			#in any case don't use the last entry twice...
			$null | Out-File $env:TEMP"\mOrganisationId.txt"
			$null | Out-File $env:TEMP"\mPersonId.txt"
		}
	}
	#endregion

	$entityNumber = $dialog.CurrentEntity.Num
	$entityGuid = $selectionSet.TypeId.EntityClassSubType
	$selectionTypeId = New-Object Autodesk.Connectivity.Explorer.Extensibility.SelectionTypeId $entityGuid
	$location = New-Object Autodesk.Connectivity.Explorer.Extensibility.LocationContext $selectionTypeId, $entityNumber
	$vaultContext.GoToLocation = $location
}