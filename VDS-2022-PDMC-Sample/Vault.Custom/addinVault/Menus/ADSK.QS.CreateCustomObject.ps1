#$vaultContext.ForceRefresh = $true
$selectionSet = $vaultContext.CurrentSelectionSet[0]
$id= $selectionSet.Id
$dialog = $dsCommands.GetCreateCustomObjectDialog($id)

$CustEntCatName = $vault.CategoryService.GetCategoryById($dialog.CurrentEntity.Cat.CatId).Name

#override the default dialog file assigned
switch($CustEntCatName)
{
	"Organisation"
	{
		$xamlFile = New-Object CreateObject.WPF.XamlFile "ADSK.QS.CustomObject.xaml", "C:\ProgramData\Autodesk\Vault 2022\Extensions\DataStandard\Vault.Custom\Configuration\ADSK.QS.CustomObjectOrganisation.xaml"
	}
	default
	{
		$xamlFile = New-Object CreateObject.WPF.XamlFile "ADSK.QS.CustomObject.xaml", "C:\ProgramData\Autodesk\Vault 2022\Extensions\DataStandard\Vault.Custom\Configuration\ADSK.QS.CustomObject.xaml"
	}
}

$dialog.XamlFile = $xamlFile
$result = $dialog.Execute()

if ($result)
{
	#differentiate for Custent definitions / categories
	$UIString = mGetUIStrings
	$CustEntCatName = $vault.CategoryService.GetCategoryById($dialog.CurrentEntity.Cat.CatId).Name
	
	#region create/update links
	If($CustEntCatName -eq $UIString["MSDCE_CO02"])#Person
	{
		try
		{		
			$companyID = Get-Content "$($env:appdata)\Autodesk\DataStandard 2022\mOrganisationId.txt"	
			if($companyID -ne "") { $link1 = $vault.DocumentService.AddLink($companyID,"CUSTENT",$dialog.CurrentEntity.Id,"Organisation->Person") } #Add Person as content to Organisation
		}
		catch
		{
			#$dsDiag.Trace("CreateCustomObject.ps1 - AddLink command failed") 
		}
	}
	#endregion
	
	#region control unique custent name for some categories
	$custent = $dialog.CurrentEntity
	
	switch($CustEntCatName)
	{
		"Person"
		{
			$mCustentExist = mFindCustent  $custent.Name $CustEntCatName

			if($mCustentExist)
			{
				#rename by adding a time stamp
				$mN1 = $custent.Name
				$mN2 = (Get-Date).ToString()
				$updatedCustent = $vault.CustomEntityService.UpdateCustomEntity($custent.Id, "$($mN1)_$($mN2)")
			}
		}
		"Organisation"
		{
			#it is handled by validating the name during run-time
		}
	}
	#endregion

	#goto location
	$entityNumber = $dialog.CurrentEntity.Num
	$entityGuid = $selectionSet.TypeId.EntityClassSubType
	$selectionTypeId = New-Object Autodesk.Connectivity.Explorer.Extensibility.SelectionTypeId $entityGuid
	$location = New-Object Autodesk.Connectivity.Explorer.Extensibility.LocationContext $selectionTypeId, $entityNumber
	$vaultContext.GoToLocation = $location
}

#in any case don't use the last entry twice...
$null | Out-File "$($env:appdata)\Autodesk\DataStandard 2022\mOrganisationId.txt"
$null | Out-File "$($env:appdata)\Autodesk\DataStandard 2022\mPersonId.txt"