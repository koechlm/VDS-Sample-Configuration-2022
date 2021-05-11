#region disclaimer
#=============================================================================
# PowerShell script sample for Vault Data Standard                            
#                                                                             
# Copyright (c) Autodesk - All rights reserved.                               
#                                                                             
# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER   
# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT. 
#=============================================================================
#endregion

#read UIStrings (only VDS dialogs/tabs do this as a default)
$UIString = mGetUIStrings

#region variables
# change the quoted display name according your Vault Property Definition
	$_ReplacedByFilePropDispName = $UIString["ADSK-GoToNavigation_Prop02"]
#endregion

$currentSelected = $vaultContext.CurrentSelectionSet[0]
$folderId = $currentSelected.Id
#if selected object is of type 'FILE' then use $vaultContext.NavSelectionSet[0].Id,
#it will give you back the folder Id where this file is located
if ($currentSelected.TypeId.EntityClassId -eq "FILE")
{
	$folderId = $vaultContext.NavSelectionSet[0].Id
	$mFileMasterId = $currentSelected.Id #current selection returns the master ID
}

$mLatestFile = $vault.DocumentService.GetLatestFileByMasterId($mFileMasterId)

#get properties of selected file
Try{
	$PropDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("FILE")
	$propDefIds = @()
	$PropDefs | ForEach-Object {
		$propDefIds += $_.Id
	} 
	$mPropDef = $propDefs | Where-Object { $_.DispName -eq $_ReplacedByFilePropDispName}
	$mEntIDs = @()
	$mEntIDs += $mLatestFile.Id
	$mPropDefIDs = @()
	$mPropDefIDs += $mPropDef.Id
	$mProp = $vault.PropertyService.GetProperties("FILE",$mEntIDs, $mPropDefIDs)
	$mVal = $mProp[0].Val
	IF(-not $mVal){
		[System.Windows.MessageBox]::Show([String]::Format($UIString["ADSK-GoToNavigation_MSG00"], $_ReplacedByFilePropDispName), $UIString["ADSK-GoToNavigation_MNU00"])
		return
	}
}
Catch{
	[System.Windows.MessageBox]::Show([String]::Format($UIString["ADSK-GoToNavigation_MSG00"], $_ReplacedByFilePropDispName), $UIString["ADSK-GoToNavigation_MNU00"])
	return
}

$srchConds = New-Object autodesk.Connectivity.WebServices.SrchCond[] 1
	$srchCond = New-Object autodesk.Connectivity.WebServices.SrchCond
	$propDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("FILE")
	$propNames = @("Name")
	$propDefIds = @{}
	foreach($name in $propNames) {
		$propDef = $propDefs | Where-Object { $_.SysName -eq $name }
		$propDefIds[$propDef.Id] = $propDef.DispName
	}
	$srchCond.PropDefId = $propDef.Id
	$srchCond.SrchOper = 3
	$srchCond.SrchTxt = $mVal
	$srchCond.PropTyp = [Autodesk.Connectivity.WebServices.PropertySearchType]::SingleProperty
	$srchCond.SrchRule = [Autodesk.Connectivity.WebServices.SearchRuleType]::Must
	$srchConds[0] = $srchCond
	$srchSort = New-Object autodesk.Connectivity.WebServices.SrchSort
	$searchStatus = New-Object autodesk.Connectivity.WebServices.SrchStatus
	$bookmark = ""
$mSearchResult = $vault.DocumentService.FindFilesBySearchConditions($srchConds,$null, $null,$true,$true,[ref]$bookmark,[ref]$searchStatus)

If (!$mSearchResult) 
{ 
	[System.Windows.MessageBox]::Show([String]::Format($UIString["ADSK-GoToNavigation_MSG01"], $mVal, $_ReplacedByFilePropDispName), $UIString["ADSK-GoToNavigation_MNU00"])
	return
}

$folderId = $mSearchResult[0].FolderId
$fileName = $mSearchResult[0].Name

$folder = $vault.DocumentService.GetFolderById($folderId)
$path=$folder.FullName+"/"+$fileName

$selectionId = [Autodesk.Connectivity.Explorer.Extensibility.SelectionTypeId]::File
$location = New-Object Autodesk.Connectivity.Explorer.Extensibility.LocationContext $selectionId, $path
$vaultContext.GoToLocation = $location
