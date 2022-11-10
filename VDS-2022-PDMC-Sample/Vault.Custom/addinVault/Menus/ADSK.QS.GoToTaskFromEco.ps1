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

#an ECO likely links multiple tasks; the user needs to select one from the list; the selection writes the txt file
$mTargetObject = Get-Content "$($env:appdata)\Autodesk\DataStandard 2022\mECOTabClick.txt"
if (-not $mTargetObject) {
    $result = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError("No Tasks is selected in the ECO-Task Tab. Select a Task first and try again.", "ECO-Tasks")
}
else {
    $mCustent = $vault.CustomEntityService.GetCustomEntitiesByIds(@($mTargetObject))[0]

    #identify custom object definition and unique (system name)
    $custentNumber = $mCustent.Num
    $custentDefId = $mCustent.CustEntDefId
    $custentName = ($vault.CustomEntityService.GetAllCustomEntityDefinitions() | Where-Object { $_.Id -eq $custentDefId }).Name

    #custom objects don't have a pre-defined selectiontypeID, so lets create one
    $selectionTypeId = New-Object Autodesk.Connectivity.Explorer.Extensibility.SelectionTypeId($custentName)
    $location = New-Object Autodesk.Connectivity.Explorer.Extensibility.LocationContext $selectionTypeId, $custentNumber
    $vaultContext.GoToLocation = $location    
}

#clean-up selection
$mSelItem = $null
$mOutFile = "mECOTabClick.txt"

$mSelItem | Out-File "$($env:appdata)\Autodesk\DataStandard 2022\$($mOutFile)"
	