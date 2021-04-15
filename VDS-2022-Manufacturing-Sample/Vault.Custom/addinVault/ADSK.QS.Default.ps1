﻿
#=============================================================================#
# PowerShell script sample for Vault Data Standard                            
#			 Autodesk Vault - VDS MFG Sample 2022								  
# This sample is based on VDS 2022 RTM and adds functionality and rules		  
#                                                                             
# Copyright (c) Autodesk - All rights reserved.                               
#                                                                             
# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER   
# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.  
#=============================================================================#

#this function will be called to check if the Ok button can be enabled
function ActivateOkButton
{
		return Validate;
}

# sample validation function
# finds all function definition with names beginning with
# ValidateFile, ValidateFolder and ValidateTask respectively
# these funcions should return a boolean value, $true if the Property is valid
# $false otherwise
# As soon as one property validation function returns $false the entire Validate function will return $false
function Validate
{
	if ($Prop["_ReadOnly"].Value){
		return $false
	}

	$mWindowName = $dsWindow.Name
	switch($mWindowName)
	{
		"FileWindow"
		{
			foreach ($func in dir function:ValidateFile*) { if(!(&$func)) { return $false } }
			return $true
		}
		"FolderWindow"
		{
			foreach ($func in dir function:ValidateFolder*) { if(!(&$func)) { return $false } }
			return $true
		}
		"CustomObjectWindow"
		{
			foreach ($func in dir function:ValidateCustomObject*) { if(!(&$func)) { return $false } }
			return $true
		}
		default { return $true }
	}
    
}

# sample validation function for the FileName property
# if the File Name is empty the validation will fail
function ValidateFileName
{
	if($Prop["_FileName"].Value -or !$dsWindow.FindName("DSNumSchmsCtrl").NumSchmFieldsEmpty)
	{
		return $true;
	}
	return $false;
}

function ValidateFolderName
{
	if($Prop["_FolderName"].Value -or !$dsWindow.FindName("DSNumSchmsCtrl").NumSchmFieldsEmpty)
	{
		return $true;
	}
	return $false;
}

function ValidateCustomObjectName
{
	if($Prop["_CustomObjectName"].Value -or !$dsWindow.FindName("DSNumSchmsCtrl").NumSchmFieldsEmpty)
	{
		return $true;
	}
	return $false;
}

function InitializeTabWindow
{
	#$dsDiag.ShowLog()
	#$dsDiag.Inspect()
}

function InitializeWindow
{	      
	#begin rules applying commonly
	$Prop["_Category"].add_PropertyChanged({
        if ($_.PropertyName -eq "Value")
        {
			#region VDS MFG Sample
				#$Prop["_NumSchm"].Value = $Prop["_Category"].Value
				m_CategoryChanged
			#endregion
        }		
    })
	#end rules applying commonly
	$mWindowName = $dsWindow.Name
	switch($mWindowName)
	{
		"FileWindow"
		{
			#rules applying for File
			$dsWindow.Title = SetWindowTitle $UIString["LBL24"] $UIString["LBL25"] $Prop["_FileName"].Value
			if ($Prop["_CreateMode"].Value)
			{
				if ($Prop["_IsOfficeClient"].Value)
				{
					$Prop["_Category"].Value = $UIString["CAT2"]
				}
				else
				{
					$Prop["_Category"].Value = $UIString["CAT1"]
				}
			}
			#region VDS MFG Sample to get category from selected template
			$dsWindow.FindName("DocTypeCombo").add_SelectionChanged({
					mResetTemplates
				})
			$dsWindow.FindName("TemplateCB").add_SelectionChanged({
				m_TemplateChanged})
			#endregion VDS MFG Sample			
		}
		"FolderWindow"
		{
			#rules applying for Folder
			$dsWindow.Title = SetWindowTitle $UIString["LBL29"] $UIString["LBL30"] $Prop["_FolderName"].Value
			if ($Prop["_CreateMode"].Value)
			{
				$Prop["_Category"].Value = $UIString["CAT5"]
			}
			#region VDS MFG Sample - for imported folders easily set title to folder name on edit
			If ($Prop["_EditMode"].Value) {
				If ($Prop["_XLTN_TITLE"]){
					IF ($Prop["_XLTN_TITLE"].Value -eq $null) {
						$Prop["_XLTN_TITLE"].Value = $Prop["Name"].Value
					}
				}
			}
			#endregion VDS MFG Sample
		}
		"CustomObjectWindow"
		{
			#rules applying for Custom Object
			$dsWindow.Title = SetWindowTitle $UIString["LBL61"] $UIString["LBL62"] $Prop["_CustomObjectName"].Value
			if ($Prop["_CreateMode"].Value)
			{
				$Prop["_Category"].Value = $Prop["_CustomObjectDefName"].Value

				#region VDS MFG Sample
					$dsWindow.FindName("Categories").IsEnabled = $false
					$dsWindow.FindName("NumSchms").Visibility = "Collapsed"
					$Prop["_NumSchm"].Value = $Prop["_Category"].Value
				#endregion
			}
		}

		"ReserveNumberWindow"
		{
			$dsWindow.FindName("cmbNumType").add_SelectionChanged({
				mGetNumSchms
			})
		}

	}
}

function SetWindowTitle($newFile, $editFile, $name)
{
       if ($Prop["_CreateMode"].Value)
       {
              $windowTitle = $newFile            
       }
       elseif ($Prop["_EditMode"].Value)
       {
			if ($Prop["_ReadOnly"].Value){
				$windowTitle = "$($editFile) - $($name) - $($UIString["LBL26"])"
				$dsWindow.FindName("btnOK").ToolTip = $UIString["LBL26"]
            }
			else{
				$windowTitle = "$($editFile) - $($name)"
			}
       }
       return $windowTitle
}


function OnLogOn
{
	#Executed when User logs on Vault; $vaultUsername can be used to get the username, which is used in Vault on login
}
function OnLogOff
{
	#Executed when User logs off Vault
}

function GetTitleWindow
{
	$message = "Autodesk Data Standard - Create/Edit "+$Prop["_FileName"]
	return $message
}

#fired when the file selection changes
function OnTabContextChanged
{
	$xamlFile = [System.IO.Path]::GetFileName($VaultContext.UserControl.XamlFile)
	
	if ($VaultContext.SelectedObject.TypeId.SelectionContext -eq "FileMaster" -and $xamlFile -eq "ADSK.QS.CAD BOM.xaml")
	{
		$fileMasterId = $vaultContext.SelectedObject.Id
		$file = $vault.DocumentService.GetLatestFileByMasterId($fileMasterId)
		$bom = @(GetFileBOM($file.id))
		$dsWindow.FindName("bomList").ItemsSource = $bom
	}
	if ($VaultContext.SelectedObject.TypeId.SelectionContext -eq "ItemMaster" -and $xamlFile -eq "Associated Files.xaml")
	{
		$items = $vault.ItemService.GetItemsByIds(@($vaultContext.SelectedObject.Id))
		$item = $items[0]
		$itemids = @($item.Id)
		$assocFiles = @(GetAssociatedFiles $itemids $([System.IO.Path]::GetDirectoryName($VaultContext.UserControl.XamlFile)))
		$dsWindow.FindName("AssoicatedFiles").ItemsSource = $assocFiles
	}
	if ($VaultContext.SelectedObject.TypeId.SelectionContext -eq "ItemMaster" -and $xamlFile -eq "ADSK.QS.ItemEdit.xaml")
	{
		$items = $vault.ItemService.GetItemsByIds(@($vaultContext.SelectedObject.Id))
		$item = $items[0]
		$itemids = @($item.Id)
		$mItemEditable = mItemEditable($itemids) #note - checks the current state to activate buttons, but this might change over time; therefore the state is local
	}
	
	if ($VaultContext.SelectedObject.TypeId.SelectionContext -eq "ChangeOrder" -and $xamlFile -eq "ADSK.QS.EcoEdit.xaml")
	{
		$number=$vaultContext.SelectedObject.Label
		$mECO = $vault.ChangeOrderService.GetChangeOrderByNumber($number)
		$mEcoEditable = mEcoEditable($mECO.Id) #note - checks the current state to activate buttons, but this might change over time; therefore the state is local
	}

	#region derivation tree
	if ($VaultContext.SelectedObject.TypeId.SelectionContext -eq "FileMaster" -and $xamlFile -eq "ADSK.QS.DerivationTree.xaml")
	{
		if($dsWindow.FindName("chkAutoUpdate").IsChecked)
		{
			mDerivationTreeUpdateView #$vaultContext.SelectedObject.Id
			$dsWindow.FindName("btnUpdate").IsEnabled = $false
		}
		if($dsWindow.FindName("chkAutoUpdate").IsChecked -eq $false)
		{ 
			mDerivationTreeResetView
		}
	}
	#endregion derivation tree
}

function GetNewCustomObjectName
{
	#region VDS MFG Sample
		$m_Cat = $Prop["_Category"].Value
		switch ($m_Cat)
		{
			$UIString["MSDCE_CO02"] #Person
			{
				if($dsWindow.FindName("DSNumSchmsCtrl").NumSchmFieldsEmpty -eq $false)
				{
					$Prop["_XLTN_IDENTNUMBER"].Value = $Prop["_GeneratedNumber"].Value
				}
				$customObjectName = $Prop["_XLTN_FIRSTNAME"].Value + " " + $Prop["_XLTN_LASTNAME"].Value
				return $customObjectName
			}

			Default 
			{
				#region - default configuration's behavior
				if($dsWindow.FindName("DSNumSchmsCtrl").NumSchmFieldsEmpty)
				{	
					#$dsDiag.Trace("read text from TextBox CUSTOMOBJECTNAME")
					$customObjectName = $dsWindow.FindName("CUSTOMOBJECTNAME").Text
					#$dsDiag.Trace("customObjectName = $customObjectName")
				}
				else{
					#$dsDiag.Trace("-> GenerateNumber")
					$customObjectName = $Prop["_GeneratedNumber"].Value
					#$dsDiag.Trace("customObjectName = $customObjectName")
				}
				return $customObjectName
				#endregion - default configuration's behavior
			}
		}
	#endregion VDS MFG Sample
}

#Constructs the filename(numschems based or handtyped)and returns it.
function GetNewFileName
{
	$dsDiag.Trace(">> GetNewFileName")
	if($dsWindow.FindName("DSNumSchmsCtrl").NumSchmFieldsEmpty)
	{	
		$dsDiag.Trace("read text from TextBox FILENAME")
		$fileName = $dsWindow.FindName("FILENAME").Text
		$dsDiag.Trace("fileName = $fileName")
	}
	else{
		$dsDiag.Trace("-> GenerateNumber")
		$fileName = $Prop["_GeneratedNumber"].Value
		$dsDiag.Trace("fileName = $fileName")
		#VDS MFG Sample
			If($Prop["_XLTN_PARTNUMBER"]) { $Prop["_XLTN_PARTNUMBER"].Value = $Prop["_GeneratedNumber"].Value }
		#VDS MFG Sample
	}
	$newfileName = $fileName + $Prop["_FileExt"].Value
	$dsDiag.Trace("<< GetNewFileName $newfileName")
	return $newfileName
}

function GetNewFolderName
{
	$dsDiag.Trace(">> GetNewFolderName")
	if($dsWindow.FindName("DSNumSchmsCtrl").NumSchmFieldsEmpty)
	{	
		$dsDiag.Trace("read text from TextBox FOLDERNAME")
		$folderName = $dsWindow.FindName("FOLDERNAME").Text
		$dsDiag.Trace("folderName = $folderName")
	}
	else{
		$dsDiag.Trace("-> GenerateNumber")
		$folderName = $Prop["_GeneratedNumber"].Value
		$dsDiag.Trace("folderName = $folderName")
	}
	$dsDiag.Trace("<< GetNewFolderName $folderName")
	return $folderName
}

# This function can be used to force a specific folder when using "New Standard File" or "New Standard Folder" functions.
# If an empty string is returned the selected folder is used
# ! Do not remove the function
function GetParentFolderName
{
	$folderName = ""
	return $folderName
}

function GetCategories
{
	if ($dsWindow.Name -eq "FileWindow")
	{
		#return $vault.CategoryService.GetCategoriesByEntityClassId("FILE", $true)
		#region VDS MFG Sample
			$global:mFileCategories = $vault.CategoryService.GetCategoriesByEntityClassId("FILE", $true)
			return $global:mFileCategories | Sort-Object -Property Name #ascending is the default
		#endregion
	}
	elseif ($dsWindow.Name -eq "FolderWindow")
	{
		return $vault.CategoryService.GetCategoriesByEntityClassId("FLDR", $true)
	}
	elseif ($dsWindow.Name -eq "CustomObjectWindow")
	{
		return $vault.CategoryService.GetCategoriesByEntityClassId("CUSTENT", $true)
	}
}

function GetNumSchms
{
	if ($Prop["_CreateMode"].Value)
	{
		try
		{
			#Adopted from a DocumentService call, which always pulls FILE class numbering schemes
			[System.Collections.ArrayList]$numSchems = @($vault.NumberingService.GetNumberingSchemes('FILE', 'Activated'))

			if ($numSchems.Count -gt 1)
			{
				#$numSchems = $numSchems | Sort-Object -Property IsDflt -Descending
				#region VDS MFG Sample
					$mWindowName = $dsWindow.Name
					switch($mWindowName)
					{
						"FileWindow"
						{
							$_FilteredNumSchems = $numSchems | Where { $_.IsDflt -eq $true}
							$Prop["_NumSchm"].Value = $_FilteredNumSchems[0].Name
							$dsWindow.FindName("NumSchms").IsEnabled = $false
							return $_FilteredNumSchems
						}

						"FolderWindow" 
						{
							#numbering schemes are available for items and files specificly; 
							#for folders we use the file numbering schemes and filter to these, that have a corresponding name in folder categories
							$_FolderCats = $vault.CategoryService.GetCategoriesByEntityClassId("FLDR", $true)
							$_FilteredNumSchems = @()
							Foreach ($item in $_FolderCats) 
							{
								$_temp = $numSchems | Where { $_.Name -eq $item.Name}
								$_FilteredNumSchems += ($_temp)
							}
							#we need an option to unselect a previosly selected numbering; to achieve that we add a virtual one, named "None"
							$noneNumSchm = New-Object 'Autodesk.Connectivity.WebServices.NumSchm'
							$noneNumSchm.Name = "None"
							$_FilteredNumSchems += ($noneNumSchm)

							return $_FilteredNumSchems
						}

						"CustomObjectWindow"
						{
							$_FilteredNumSchems = $numSchems | Where { $_.Name -eq $Prop["_Category"].Value}
							return $_FilteredNumSchems
						}

						default
						{
							$numSchems = $numSchems | Sort-Object -Property IsDflt -Descending
							return $numSchems
						}
					}
				#region
			}
			Else {
				$dsWindow.FindName("NumSchms").IsEnabled = $false				
			}
			return $numSchems
		}
		catch [System.Exception]
		{		
			#[System.Windows.MessageBox]::Show($error)
		}
	}
}


# Decides if the NumSchmes field should be visible
function IsVisibleNumSchems
{
	$ret = "Collapsed"
	$numSchems = $vault.DocumentService.GetNumberingSchemesByType([Autodesk.Connectivity.WebServices.NumSchmType]::Activated)
	if($numSchems.Length -gt 0)
	{	$ret = "Visible" }
	return $ret
}

#Decides if the FileName should be enabled, it should only when the NumSchmField isnt
function ShouldEnableFileName
{
	$ret = "true"
	$numSchems = $vault.DocumentService.GetNumberingSchemesByType([Autodesk.Connectivity.WebServices.NumSchmType]::Activated)
	if($numSchems.Length -gt 0)
	{	$ret = "false" }
	return $ret
}

function ShouldEnableNumSchms
{
	$ret = "false"
	$numSchems = $vault.DocumentService.GetNumberingSchemesByType([Autodesk.Connectivity.WebServices.NumSchmType]::Activated)
	if($numSchems.Length -gt 0)
	{	$ret = "true" }
	return $ret
}

#define the parametrisation for the number generator here
function GenerateNumber
{
	$dsDiag.Trace(">> GenerateNumber")
	$selected = $dsWindow.FindName("NumSchms").Text
	if($selected -eq "") { return "na" }

	$ns = $global:numSchems | Where-Object { $_.Name.Equals($selected) }
	switch ($selected) {
		"Sequential" { $NumGenArgs = @(""); break; }
		default      { $NumGenArgs = @(""); break; }
	}
	$dsDiag.Trace("GenerateFileNumber($($ns.SchmID), $NumGenArgs)")
	$vault.DocumentService.GenerateFileNumber($ns.SchmID, $NumGenArgs)
	$dsDiag.Trace("<< GenerateNumber")
}

#define here how the numbering preview should look like
function GetNumberPreview
{
	$selected = $dsWindow.FindName("NumSchms").Text
	switch ($selected) {
		"Sequential" { $Prop["_FileName"].Value="???????"; break; }
		"Short" { $Prop["_FileName"].Value=$Prop["Project"].Value + "-?????"; break; }
		"Long" { $Prop["_FileName"].Value=$Prop["Project"].Value + "." + $Prop["Material"].Value + "-?????"; break; }
		default { $Prop["_FileName"].Value="NA" }
	}
}

#Workaround for Property names containing round brackets
#Xaml fails to parse
function ItemTitle
{
    if ($Prop)
	{
       $val = $Prop["_XLTN_TITLE_ITEM_CO"].Value
	   return $val
    }
}

#Workaround for Property names containing round brackets
#Xaml fails to parse
function ItemDescription
{
	if($Prop)#Tab gets loaded before the SelectionChanged event gets fired resulting with null Prop. Happens when the vault is started with Change Order as the last view.
    {
       $val = $Prop["_XLTN_DESCRIPTION_ITEM_CO"].Value
	   return $val
    }
}

 
function m_TemplateChanged {
	#$dsDiag.Trace(">> Template Changed ...")
	#check if cmbTemplates is empty
	if ($dsWindow.FindName("TemplateCB").ItemsSource.Count -lt 1)
	{
		#$dsDiag.Trace("Template changed exits due to missing templates")
		return
	}
	$mContext = $dsWindow.DataContext
	$mTemplatePath = $mContext.TemplatePath
	$mTemplateFile = $mContext.SelectedTemplate
	$mTemplate = $mTemplatePath + "/" + $mTemplateFile
	$mFolder = $vault.DocumentService.GetFolderByPath($mTemplatePath)
	$mFiles = $vault.DocumentService.GetLatestFilesByFolderId($mFolder.Id,$false)
	$mTemplateFile = $mFiles | Where-Object { $_.Name -eq $mTemplateFile }
	$Prop["_Category"].Value = $mTemplateFile.Cat.CatName
	$mCatName = $mTemplateFile.Cat.CatName
	$dsWindow.FindName("Categories").SelectedValue = $mCatName
	If ($mCatName) #if something went wrong the user should be able to select a category
	{
		$dsWindow.FindName("Categories").IsEnabled = $false #comment out this line if admins like to release the choice to the user
	}
	#$dsDiag.Trace(" ... TemplateChanged finished <<")
}

function m_CategoryChanged 
{
	$mWindowName = $dsWindow.Name
    switch($mWindowName)
	{
		"FileWindow"
		{
			#VDS MFG Sample uses the default numbering scheme for files; GoTo GetNumSchms function to disable this filter incase you'd like to apply numbering per category for files as well
			If ($Prop['_XLTN_AUTHOR'])
			{
				$Prop['_XLTN_AUTHOR'].Value = $VaultConnection.UserName
			}
		}

		"FolderWindow" 
		{
			$dsWindow.FindName("NumSchms").SelectedItem = $null
			$dsWindow.FindName("NumSchms").Visibility = "Collapsed"
			$dsWindow.FindName("DSNumSchmsCtrl").Visibility = "Collapsed"
			$dsWindow.FindName("FOLDERNAME").Visibility = "Visible"
					
			$Prop["_NumSchm"].Value = $Prop["_Category"].Value
			IF ($dsWindow.FindName("DSNumSchmsCtrl").Scheme.Name -eq $Prop["_Category"].Value) 
			{
				$dsWindow.FindName("DSNumSchmsCtrl").Visibility = "Visible"
				$dsWindow.FindName("FOLDERNAME").Visibility = "Collapsed"
			}
			Else
			{
				$Prop["_NumSchm"].Value = "None" #we need to reset in case a user switches back from existing numbering scheme to manual input
			}
			
			#set the start date = today for project category
			If ($Prop["_Category"].Value -eq $UIString["CAT6"] -and $Prop["_XLTN_DATESTART"] )		
			{
				$Prop["_XLTN_DATESTART"].Value = Get-Date -displayhint date
			}
		}

		"CustomObjectWindow"
		{
			#categories are bound to CO type name
		}
		default
		{
			#nothing for 'unknown' new window type names
		}			
	} #end switch window
} #end function m_CategoryChanged

function mHelp ([Int] $mHContext) {
	Try
	{
		Switch ($mHContext){
			500 {
				$mHPage = "V.2File.html";
			}
			550 {
				$mHPage = "V.3OfficeFile.html";
			}
			600 {
				$mHPage = "V.1Folder.html";
			}
			700 {
				$mHPage = "V.6CustomObject.html";
			}
			Default {
				$mHPage = "Index.html";
			}
		}
		$mHelpTarget = "C:\ProgramData\Autodesk\Vault 2022\Extensions\DataStandard\HelpFiles\"+$mHPage
		$mhelpfile = Invoke-Item $mHelpTarget 
	}
	Catch
	{
		[System.Windows.MessageBox]::Show("Help Target not found", "VDS MFG Sample Client")
	}
}
function mResetTemplates
{
	$dsWindow.FindName("TemplateCB").ItemsSource = $dsWindow.DataContext.Templates
}

function mFldrNameValidation
{
	$rootFolder = $vault.DocumentService.GetFolderByPath($Prop["_FolderPath"].Value)
	$mFldExist = mFindFolder $Prop["_FolderName"].Value $rootFolder

	If($mFldExist)
	{
		$dsWindow.FindName("FOLDERNAME").ToolTip = "Foldername exists, select a new unique one."
		$dsWindow.FindName("FOLDERNAME").BorderBrush = "Red"
		$dsWindow.FindName("FOLDERNAME").BorderThickness = "1,1,1,1"
		$dsWindow.FindName("FOLDERNAME").Background = "#FFFFDADA"
		return $false
	}
	Else
	{
		$dsWindow.FindName("FOLDERNAME").ToolTip = "Foldername is valid, press OK to create."
		$dsWindow.FindName("FOLDERNAME").BorderBrush = "#FFABADB3" #the default color
		$dsWindow.FindName("FOLDERNAME").BorderThickness = "0,1,1,0" #the default border top, right
		$dsWindow.FindName("FOLDERNAME").Background = "#FFFFFFFF"
		return $true
	}
}

function mFindFolder($FolderName, $rootFolder)
{
	$FolderPropDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("FLDR")
    $FolderNamePropDef = $FolderPropDefs | where {$_.SysName -eq "Name"}
    $srchCond = New-Object 'Autodesk.Connectivity.WebServices.SrchCond'
    $srchCond.PropDefId = $FolderNamePropDef.Id
    $srchCond.PropTyp = "SingleProperty"
    $srchCond.SrchOper = 3 #is equal
    $srchCond.SrchRule = "Must"
    $srchCond.SrchTxt = $FolderName

    $bookmark = ""
    $status = $null
    $totalResults = @()
    while ($status -eq $null -or $totalResults.Count -lt $status.TotalHits)
    {
        $results = $vault.DocumentService.FindFoldersBySearchConditions(@($srchCond),$null, @($rootFolder.Id), $false, [ref]$bookmark, [ref]$status)

        if ($results -ne $null)
        {
            $totalResults += $results
        }
        else {break}
    }
    return $totalResults;
}