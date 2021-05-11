function InitializeFileNameValidation()
{
    if ($Prop["_CreateMode"].Value)
    {
	    if($dsWindow.Name -eq 'InventorWindow')
	    {
            $Prop["DocNumber"].CustomValidation = { FileNameCustomValidation }
		}
        elseif($dsWindow.Name -eq 'AutoCADWindow')
		{
		    $Prop["GEN-TITLE-DWG"].CustomValidation = { FileNameCustomValidation }
		}                
    }
}

function FileNameCustomValidation
{
    $DSNumSchmsCtrl = $dsWindow.FindName("DSNumSchmsCtrl")
    if ($DSNumSchmsCtrl -and -not $DSNumSchmsCtrl.NumSchmFieldsEmpty)
    {
        return $true
    }
    if($dsWindow.Name -eq 'InventorWindow')
	{
        $propertyName = "DocNumber"
	}
    elseif($dsWindow.Name -eq 'AutoCADWindow')
	{
		$propertyName = "GEN-TITLE-DWG"
	}
	
    $rootFolder = GetVaultRootFolder
    $fullFileName = [System.IO.Path]::Combine($Prop["_FilePath"].Value, $Prop["_FileName"].Value)
    if ([System.IO.File]::Exists($fullFileName))
    {
		$Prop["$($propertyName)"].CustomValidationErrorMessage = "$($UIString["MSG4"])"
        return $false
    }
    $isinvault = FileExistsInVault($rootFolder.FullName + "/" + $Prop["Folder"].Value.Replace(".\", "") + $Prop["_FileName"].Value)
    if ($isinvault)
    {
		$Prop["$($propertyName)"].CustomValidationErrorMessage = "$($UIString["VAL12"])"
        return $false
    }
    if ($vault.DocumentService.GetUniqueFileNameRequired())
    {    
        $result = FindFile -fileName $Prop["_FileName"].Value
        if ($result)
        {
			$Prop["$($propertyName)"].CustomValidationErrorMessage = "$($UIString["VAL13"])"
            return $false
        }
    }
    return $true
}

function FindFile($fileName)
{
    $filePropDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("FILE")
    $fileNamePropDef = $filePropDefs | where {$_.SysName -eq "ClientFileName"}
    $srchCond = New-Object 'Autodesk.Connectivity.WebServices.SrchCond'
    $srchCond.PropDefId = $fileNamePropDef.Id
    $srchCond.PropTyp = "SingleProperty"
    $srchCond.SrchOper = 3 #is equal
    $srchCond.SrchRule = "Must"
    $srchCond.SrchTxt = $fileName

    $bookmark = ""
    $status = $null
    $totalResults = @()
    while ($status -eq $null -or $totalResults.Count -lt $status.TotalHits)
    {
        $results = $vault.DocumentService.FindFilesBySearchConditions(@($srchCond),$null, $null, $false, $true, [ref]$bookmark, [ref]$status)

        if ($results -ne $null)
        {
            $totalResults += $results
        }
        else {break}
    }
    return $totalResults;
}

function FileExistsInVault($vaultPath)
{
    $pathWithoutDot = $vaultPath.Replace("/.", "/")
    $pathInVaultFormat = $pathWithoutDot.Replace("\", "/")
    try
    {
        $files = $vault.DocumentService.FindLatestFilesByPaths(@($pathInVaultFormat))
        if ($files.Count -gt 0)
        {
            if ($files[0].Id -ne -1)
            { return $true }
        }
    }
    catch
    {
        #$dsDiag.Inspect()
    }    
    return $false
}