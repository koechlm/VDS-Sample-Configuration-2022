﻿#region disclaimer
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

#command to create a new ECO linked to the selected project
$folderId = $vaultContext.NavSelectionSet[0].Id
$vaultContext.ForceRefresh = $true
$folder = $vault.DocumentService.GetFolderById($folderId)
$path = $folder.FullName

$mFiles = @($vaultContext.CurrentSelectionSet)

#load UIStrings (they are not available as a default for menu commands
$UIString = mGetUIStrings

#create ECO and link to parent project folders only
$mParFld = $folder
IF ($folder.Cat.CatName -eq $UIString["CAT6"]) { $mProjectFound = $true }
ElseIf ($path -ne "$") {
	Do {
		$mParID = $folder.ParID
		$mParFld = $vault.DocumentService.GetFolderByID($mParID)
		IF ($mParFld.Cat.CatName -eq $UIString["CAT6"]) { $mProjectFound = $true }
	} Until (($mParFld.Cat.CatName -eq $UIString["CAT6"]) -or ($mParFld.FullName -eq "$"))
}	
If ($mProjectFound -ne $true) {
	return
}
Else {
	$folder = $mParFld
	$path = $folder.FullName
}

# Set Reference to ChangeOrderService
$mCoSrvc = $vault.ChangeOrderService
# Get Default ECO Workflow
$mCoWflow = $mCoSrvc.GetDefaultWorkflow()
# Get Default ECO Routing
$mCoRouting = $mCoSrvc.GetRoutingsByWorkflowId($mCoWflow.Id) 
$mCoDfltRouting = $mCoRouting | Where-Object { $_.IsDflt } | Select-Object -First 1

#retrieve a new ECO number
$mCoNumSchm = @($vault.NumberingService.GetNumberingSchemes("CO", "Activated")) | Where-Object { $_.IsDflt } | Select-Object -First 1
$mCoNum = $mCoSrvc.GetChangeOrderNumberBySchemeId($mCoNumSchm.SchmID)

#set the ECO title and description
$mCoTitle = "Project - " + (mGetFolderPropValue $folder.Id "Title")
$mCoDescr = "What to change in project XY"

#Set Due date to next month
$nextmonth = ((Get-Date).AddMonths(1))

#add entities to the Records tab; item or file master ids
$mItemIds = $null
$mFileIds = @()
$mFiles | ForEach-Object {
	$mFileIds += $_.Id
}

#add entities to the Files tab
$mFileAttmtsIds = $null

#$mCoProps = @(New-object Autodesk.Connectivity.WebServices.PropInst)
$mCoProps = $null
#$mCoItemAssocProps = @(New-Object Autodesk.Connectivity.WebServices.AssocPropItem)
$mCoItemAssocProps = $null
#$mCoComments = @(New-Object Autodesk.Connectivity.WebServices.MsgGroup)
$mCoComments = $null
#$mCoEmails = @(New-Object Autodesk.Connectivity.WebServices.Email)
$mCoEmails = $null

#create ChangeOrder in Vault
$ChangeOrder = $mCoSrvc.AddChangeOrder($mCoDfltRouting.Id, $mCoNum, $mCoTitle, $mCoDescr, $nextmonth, $mItemIds, $mFileAttmtsIds, $mFileIds, $mCoProps, $mCoItemAssocProps, $mCoComments, $mCoEmails)

#Edit custom properties of ECO
$propInstParam = New-Object Autodesk.Connectivity.WebServices.PropInstParam
$propInstParamArray = New-Object Autodesk.Connectivity.WebServices.PropInstParamArray

#Edit 'Project'
$propInstParam.PropDefId = mGetCOPropertyDefId("Project")
$propInstParam.Val = $folder.Name
$propInstParamArray.Items = @($propInstParam)
$propInstParamArrayArray = @($propInstParamArray)
$ent_idsArray = @($ChangeOrder.Id)
$mCoSrvc.UpdateChangeOrderProperties($ent_idsArray, $propInstParamArrayArray)

#Edit 'Change Order Type' - values are "Engineering", "System Administration", "Technical Documentation"
$propInstParam.PropDefId = mGetCOPropertyDefId("Change Order Type")
$propInstParam.Val = "Technical Documentation"
$propInstParamArray.Items = @($propInstParam)
$propInstParamArrayArray = @($propInstParamArray)
$ent_idsArray = @($ChangeOrder.Id)
$mCoSrvc.UpdateChangeOrderProperties($ent_idsArray, $propInstParamArrayArray)
	
$link = $vault.DocumentService.AddLink($folder.Id, "CO", $ChangeOrder.Id, "Parent->Child")

#navigate to the new ECO link
$selectionId = [Autodesk.Connectivity.Explorer.Extensibility.SelectionTypeId]::Folder
$location = New-Object Autodesk.Connectivity.Explorer.Extensibility.LocationContext $selectionId, $path
$vaultContext.GoToLocation = $location
#$vaultContext.CurrentSelectionSet = @($ChangeOrder)
