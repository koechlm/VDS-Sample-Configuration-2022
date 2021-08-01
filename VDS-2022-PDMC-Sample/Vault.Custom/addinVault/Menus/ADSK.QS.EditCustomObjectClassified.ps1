$vaultContext.ForceRefresh = $true
$id=$vaultContext.CurrentSelectionSet[0].Id
$dialog = $dsCommands.GetEditCustomObjectDialog($id)

$xamlFile = New-Object CreateObject.WPF.XamlFile "CustomEntityXaml", "%ProgramData%\Autodesk\Vault 2022\Extensions\DataStandard\Vault.Custom\Configuration\ADSK.QS.CustomObjectClassified.xaml"
$dialog.XamlFile = $xamlFile

$result = $dialog.Execute()
$dsDiag.Trace($result)

if($result)
{
	$custent = $vault.CustomEntityService.GetCustomEntitiesByIds(@($id))[0]
	$cat = $vault.CategoryService.GetCategoryById($custent.Cat.CatId)
	switch($cat.Name)
	{
		"Term"
		{
			$mN = mGetCustentPropValue $custent.Id "Term EN"
			$updatedCustent = $vault.CustomEntityService.UpdateCustomEntity($custent.Id, $mN)
		}
		"Class"
		{
			$mN = mGetCustentPropValue $custent.Id "Class"
			$updatedCustent = $vault.CustomEntityService.UpdateCustomEntity($custent.Id, $mN)
		}
	}

	
	#region update links
	$parentID = Get-Content $env:TEMP"\mParentId.txt"
	$childID = $dialog.CurrentEntity.Id
		
	[System.Collections.ArrayList]$existingTargetLnks = @()
	$existingTargetLnks = $vault.DocumentService.GetLinksByTargetEntityIds(@($childID))
	
	if($existingTargetLnks.Count -gt 1)
	{
		[System.Windows.MessageBox]::Show("A classified object must not have more than a single parent; correct your links manually and repeat the edit.", "VDS PDMC-Sample Classification")
	}
	elseif($existingTargetLnks.Count -eq 1)
	{
		$currentLnk = $existingTargetLnks[0]
		if($existingTargetLnks[0].ParentId -ne $parentID)
		{
			#delete the old one
			$vault.DocumentService.DeleteLinks(@($currentLnk.Id))
			#create a new link
			$link = $vault.DocumentService.AddLink($parentID,"CUSTENT", $childID, "Parent->Child")
		}
	}
	elseif($existingTargetLnks.Count -eq 0)
	{
		#create a new link
			$dsDiag.Inspect()
		$link = $vault.DocumentService.AddLink($parentID,"CUSTENT", $childID, "Parent->Child")
	}

	#in case cancel / close Window (Window button X), remove last entries as well...
	$null | Out-File $env:TEMP"\mParentId.txt"

	#endregion

}