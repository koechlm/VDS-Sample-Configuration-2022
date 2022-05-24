#region disclaimer
	#===============================================================================
	# PowerShell script sample														
	# Author: Markus Koechl														
	# Copyright (c) Autodesk 2021												
	#																				
	# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER     
	# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES   
	# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.   
	#===============================================================================
#endregion

Add-Type @"
public class IEC61355Data
{
	public string Id {get;set;}
	public string SubClass {get;set;}
	public string Example {get;set;}
	public string Code {get;set;}
	public string SubClassDE {get;set;}
	public string ExampleDE {get;set;}
	public string Favorite {get;set;}
	public string Path {get;set;}
	public string PathCode {get;set;}
}
"@

function mInitializeIEC61355
{              							
	If(-not $global:mIEC61355Initialized)
	{
		$Global:NavigatedOrSearched = ""
		#get the property definitions for custom objects
		if(-not $Global:CustentPropDefs) {	$Global:CustentPropDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("CUSTENT")}

		If(-not $UIString["Adsk.IEC61355.00"]) { $UIString = mGetUIStrings } #the psm library might not get the VDS default variable
		mAddIEC61355Combo -_CoName "Segment" #enables classification level 1

		#Search tab
		$mWindowName = $AssignClsWindow.Name
		if($mWindowName -eq "AutoCADWindow" -or $mWindowName -eq "InventorWindow")
		{
			$mTagPropName = "DCC"
		}
		else
		{
			$mTagPropName = "Document Code (DCC)"
		}

		if($Prop[$mTagPropName].Value -ne "")
		{
			#activate the search tab if it isn't
			$AssignClsWindow.FindName("tabIEC61355Search").IsSelected = $true
			$AssignClsWindow.FindName("txtSearchIEC61355").Text = $Prop[$mTagPropName].Value
			mSearchIEC61355

			if($AssignClsWindow.FindName("dataGrdIEC61355Found").Items.Count -eq 1)
			{
				$AssignClsWindow.FindName("dataGrdIEC61355Found").SelectedItem = $AssignClsWindow.FindName("dataGrdIEC61355Found").Items[0]
				mApplyIEC61355
			}
		}

		$AssignClsWindow.FindName("dataGrdIEC61355Found").add_SelectionChanged({
			param($mSender, $SelectionChangedEventArgs)
			#$dsDiag.Trace(".. TermsFoundSelection")
			IF($AssignClsWindow.FindName("dataGrdIEC61355Found").SelectedItem){
				$AssignClsWindow.FindName("btnIEC61355Adopt").IsEnabled = $true
				$AssignClsWindow.FindName("btnIEC61355Adopt").IsDefault = $true
			}
			Else {
				$AssignClsWindow.FindName("btnIEC61355Adopt").IsEnabled = $false
				if($AssignClsWindow.FindName("btnSearchIEC61355")) { $AssignClsWindow.FindName("btnSearchIEC61355").IsDefault = $true}
			}
		})

		$Global:mIEC61355Initialized = $true
	}

}


function mSearchIEC61355
{
	#don't mix the result with a previously navigated one
	mResetIEC61355BrdCrmb

	Try {
		#$dsDiag.Trace(">> search COs terms")
		$AssignClsWindow.FindName("dataGrdIEC61355Found").ItemsSource = $null

		$mSearchText1 = $AssignClsWindow.FindName("txtSearchIEC61355").Text

		#search bookmark or all fields
		if($AssignClsWindow.FindName("radioSearchBkmk").IsChecked)
		{
			$srchConds = New-Object autodesk.Connectivity.WebServices.SrchCond[] 3
			$srchConds[0]= mCreateIEC61355SearchCond "Category Name" "Class" "AND"
			$srchConds[1]= mCreateIEC61355SearchCond "Standard" "IEC61355" "AND"
			$srchConds[2]= mCreateIEC61355SearchCond "Bookmark" $mSearchText1 "AND"
		}
		else
		{
			$srchConds = New-Object autodesk.Connectivity.WebServices.SrchCond[] 8
			$srchConds[0]= mCreateIEC61355SearchCond "Category Name" "Class" "AND"
			$srchConds[1]= mCreateIEC61355SearchCond "Standard" "IEC61355" "AND"
			$srchConds[2]= mCreateIEC61355SearchCond "Name" $mSearchText1 "OR"
			$srchConds[3]= mCreateIEC61355SearchCond "Term DE" $mSearchText1 "OR"
			$srchConds[4]= mCreateIEC61355SearchCond "Comments" $mSearchText1 "OR"
			$srchConds[5]= mCreateIEC61355SearchCond "Comments DE" $mSearchText1 "OR"
			$srchConds[6]= mCreateIEC61355SearchCond "Bookmark" $mSearchText1 "OR"
			$srchConds[7]= mCreateIEC61355SearchCond "Code" $mSearchText1 "OR"
		}

		#the default search condition object type is custom object "Group"
		$srchSort = New-Object autodesk.Connectivity.WebServices.SrchSort
		$searchStatus = New-Object autodesk.Connectivity.WebServices.SrchStatus
		$bookmark = ""
		$mResultAll = New-Object 'System.Collections.Generic.List[Autodesk.Connectivity.WebServices.CustEnt]'

		while(($searchStatus.TotalHits -eq 0) -or ($mResultAll.Count -lt $searchStatus.TotalHits))
		{
			$mResultPage = $vault.CustomEntityService.FindCustomEntitiesBySearchConditions($srchConds,@($srchSort),[ref]$bookmark,[ref]$searchStatus)
			If ($searchStatus.IndxStatus -ne "IndexingComplete" -or $searchStatus -eq "IndexingContent")
			{
				#check the indexing status; you might return a warning that the result bases on an incomplete index, or even return with a stop/error message, that we need to have a complete index first
				$AssignClsWindow.FindName("txtIEC61355StatusMsg").Text = $UIString["Adsk.QS.Classification_12"]
				$AssignClsWindow.FindName("txtIEC61355StatusMsg").Visibility = "Visible"
			}
			If($mResultPage.Count -ne 0)
			{
				$mResultAll.AddRange($mResultPage)
			}
			else 
			{ 
				$AssignClsWindow.FindName("txtIEC61355StatusMsg").Text = $UIString["ClassTerms_MSG03"]
				$AssignClsWindow.FindName("txtIEC61355StatusMsg").Visibility = "Visible"
				break;
			}

			#limit the search result to the first result page;
			$AssignClsWindow.FindName("txtIEC61355StatusMsg").Text = $UIString["ClassTerms_MSG02"]
			$AssignClsWindow.FindName("txtIEC61355StatusMsg").Visibility = "Visible"
			break; #limit the search result to the first result page; page scrolling not implemented in this snippet release
		}

		If($mResultAll.Count -lt 1){		
			Return
		}
		Else{
			$AssignClsWindow.FindName("txtIEC61355StatusMsg").Visibility = "Collapsed"
		}
		
		# 	retrieve all properties of the COs found
		$_data = @()
		#derive data set from result do display; items have system properties like number, title, but others require to query the entity properties
		$mResultItemIds = @()
		$mResultAll | ForEach-Object { $mResultItemIds += $_.Id}
		$mPropDefs = @() #to be consumed by GetProperties
		$mPropDict = @{} #to be leveraged reading property by Name instead of Def.Id
		$mDefId += ($Global:CustentPropDefs | Where-Object { $_.DispName -eq "Name"}).Id
		$mPropDefs += $mDefID
		$mPropDict.Add("Name", $mDefID)
		$mDefId = ($Global:CustentPropDefs | Where-Object { $_.DispName -eq "Code"}).Id
		$mPropDefs += $mDefID
		$mPropDict.Add("Code", $mDefID)
		$mDefId = ($Global:CustentPropDefs | Where-Object { $_.DispName -eq "Comments"}).Id
		$mPropDefs += $mDefID
		$mPropDict.Add("Comments", $mDefID)
		$mDefId = ($Global:CustentPropDefs | Where-Object { $_.DispName -eq "Term DE"}).Id
		$mPropDefs += $mDefID
		$mPropDict.Add("Term DE", $mDefID)
		$mDefId = ($Global:CustentPropDefs | Where-Object { $_.DispName -eq "Comments DE"}).Id
		$mPropDefs += $mDefID
		$mPropDict.Add("Comments DE",$mDefID)

		$mPropInst = $vault.PropertyService.GetProperties("CUSTENT", $mResultItemIds, $mPropDefs)

		#build the table to display items with properties
		$Global:mSubClassesPaths = @{}
		foreach($item in $mResultAll)
		{
			#first get the paths to extend the search result for each technical area that a resutl might belong to

			$links_3 = @()
			$mLinkedCustObjects_3 = @()
			$links_3 = $vault.DocumentService.GetLinksByTargetEntityIds(@($item.Id))
			If($links_3)
			{
				$linkIds_3 = @()
				$links_3 | ForEach-Object { $linkIds_3 += $_.ParentId }
				$mLinkedCustObjects_3 = $vault.CustomEntityService.GetCustomEntitiesByIds($linkIds_3);
				if($mLinkedCustObjects_3)
				{
					$mIsoObjects_3 = @()
					$mLinkedCustObjects_3 | ForEach-Object { $mIsoObjects_3 += mConvertCustentsToIEC61355Objects $_ }
				}
			}
			$links_2 = $vault.DocumentService.GetLinksByTargetEntityIds($linkIds_3)
			If($links_2)
			{
				$linkIds_2 = @()
				$links_2 | ForEach-Object { $linkIds_2 += $_.ParentId }
				$mLinkedCustObjects_2 = $vault.CustomEntityService.GetCustomEntitiesByIds($linkIds_2);
				if($mLinkedCustObjects_2)
				{
					$mIsoObjects_2 = @()
					$mLinkedCustObjects_2 | ForEach-Object { $mIsoObjects_2 += mConvertCustentsToIEC61355Objects $_ }
				}
			}
			$links_1 = $vault.DocumentService.GetLinksByTargetEntityIds($linkIds_2)
			If($links_1)
			{
				$linkIds_1 = @()
				$links_1 | ForEach-Object { $linkIds_1 += $_.ParentId }
				$mLinkedCustObjects_1 = $vault.CustomEntityService.GetCustomEntitiesByIds($linkIds_1);
				if($mLinkedCustObjects_1)
				{
					$mIsoObjects_1 = @()
					$mLinkedCustObjects_1 | ForEach-Object { $mIsoObjects_1 += mConvertCustentsToIEC61355Objects $_ }
				}
			}

			#build the data table for all linked paths found of the current subclass found
			if($AssignClsWindow.FindName("radioSearchBkmk").IsChecked)
			{
				$sorted_1 = $mIsoObjects_1 | Where-Object { $_.Code -eq $mSearchText1[0]}
			}
			else
			{
				$sorted_1 = $mIsoObjects_1 | Sort-Object Code
			}

			foreach ($mIso in $sorted_1) { 
				$row = New-Object IEC61355Data
				$row.Id = $item.Id
				$row.SubClass = $item.Name
				$row.Code = ($mPropInst | Where-Object { $_.EntityId -eq $item.Id -and $_.PropDefId -eq $mPropDict["Code"]}).Val
				$row.Example = ($mPropInst | Where-Object { $_.EntityId -eq $item.Id -and $_.PropDefId -eq $mPropDict["Comments"]}).Val
				$row.SubClassDE = ($mPropInst | Where-Object { $_.EntityId -eq $item.Id -and $_.PropDefId -eq $mPropDict["Term DE"]}).Val
				$row.ExampleDE = ($mPropInst | Where-Object { $_.EntityId -eq $item.Id -and $_.PropDefId -eq $mPropDict["Comments DE"]}).Val
				$row.PathCode = "$($mIso.Code) | $($mIsoObjects_2.Code) | $($mIsoObjects_3.Code)"
				$row.Path =  "$($mIso.SubClass) | $($mIsoObjects_2.SubClass) | $($mIsoObjects_3.SubClass)"
				$_data += $row

				$mPathCustents = New-Object Autodesk.Connectivity.WebServices.CustEnt[] 3
				$mPathCustents[0] = $mLinkedCustObjects_1 | Where-Object {$_.Id -eq $mIso.Id}
				$mPathCustents[1] = $mLinkedCustObjects_2[0]
				$mPathCustents[2] = $mLinkedCustObjects_3[0]

				$Global:mSubClassesPaths.Add("$($row.PathCode)-$($row.Code)", $mPathCustents)
			}
		}

		If($_data)
		{
			$AssignClsWindow.FindName("dataGrdIEC61355Found").ItemsSource = $_data
			$Global:NavigatedOrSearched = "Searched"
		}
		else
		{
			$AssignClsWindow.FindName("dataGrdIEC61355Found").ItemsSource = $null
		}
	}
	catch {
		$dsDiag.Trace("ERROR --- in m_SearchIEC61355s function") 
	}

}

function mCreateIEC61355SearchCond ([String] $PropName, [String] $mSearchTxt, [String] $AndOr) {
	$dsDiag.Trace("--SearchCond creation starts... for $PropName and $mSearchTxt ---")
	$srchCond = New-Object autodesk.Connectivity.WebServices.SrchCond
	$propDefs = $Global:CustentPropDefs
	$propNames = @($PropName)
	$propDefIds = @{}
	foreach($name in $propNames) 
	{
		$propDef = $propDefs | Where-Object { $_.dispName -eq $name }
		$propDefIds[$propDef.Id] = $propDef.DispName
	}
	$srchCond.PropDefId = $propDef.Id
	$srchCond.SrchOper = 1
	$srchCond.SrchTxt = $mSearchTxt
	$srchCond.PropTyp = [Autodesk.Connectivity.WebServices.PropertySearchType]::SingleProperty
	
	If ($AndOr -eq "AND") {
		$srchCond.SrchRule = [Autodesk.Connectivity.WebServices.SearchRuleType]::Must
	}
	Else {
		$srchCond.SrchRule = [Autodesk.Connectivity.WebServices.SearchRuleType]::May
	}
	$dsDiag.Trace("--SearchCond creation finished. ---")
	return $srchCond
} 

function mApplyIEC61355
{
	#$dsDiag.Trace("Subclass selected to copy property values")
	$mSelectedCls = $AssignClsWindow.FindName("dataGrdIEC61355Found").SelectedItem
	
	#save to keep user's last used selection
	$value = $AssignClsWindow.FindName("dataGrdIEC61355Found").SelectedItem.SubClass
	$value | Out-File "$($env:appdata)\Autodesk\DataStandard 2022\mIEC61355Id_4.txt"

	#derive the parents tree from the selected object
	$SelectedClsTree = New-Object Autodesk.Connectivity.WebServices.CustEnt[] 3

	#search or selection requires different steps to build the document tag
	if($Global:NavigatedOrSearched -eq "Searched")
	{
		$mkey = "$($mSelectedCls.PathCode)-$($mSelectedCls.Code)"
		$m1 = $Global:mSubClassesPaths[$mkey]
		$SelectedClsTree[0] = $m1[0]
		$SelectedClsTree[1] = $m1[1]
		$SelectedClsTree[2] = $m1[2]
	}
	elseif($Global:NavigatedOrSearched -eq "Navigated")
	{
		$mBreadCrumb = $AssignClsWindow.FindName("wrpIEC61355")	
		$SelectedClsTree[0] = $mBreadCrumb.Children[1].SelectedItem
		$SelectedClsTree[1] = $mBreadCrumb.Children[2].SelectedItem
		$SelectedClsTree[2] = $mBreadCrumb.Children[3].SelectedItem
	}

	$mTreeIsoData =  mConvertCustentsToIEC61355Objects $SelectedClsTree
	$mDCC = $mTreeIsoData[0].Code + $mTreeIsoData[1].Code + $mTreeIsoData[2].Code + $mSelectedCls.Code

	#todo: discuss the IEC61355 properties to be filled
	If ($dsWindow.Name -eq "AutoCADWindow" -or $dsWindow.Name -eq "InventorWindow")
	{
		$Prop["DCC"].Value = $mDCC
		$Prop["ART"].Value = $mTreeIsoData[2].SubClassDE
		$Prop["ART_PD_ENG"].Value = $mTreeIsoData[2].SubClass
		$Prop["UUArt_PD_ENG"].Value = $mSelectedCls.SubClass
		$Prop["UUArt"].Value = $mSelectedCls.SubClassDE
	}
	#todo: discuss the IEC61355 properties to be filled
	If ($dsWindow.Name -eq "FileWindow") 
	{		
		$Prop["Document Code (DCC)"].Value = $mDCC	
		$Prop["Document Type"].Value = $mTreeIsoData[2].SubClass
		$Prop["Document Type DE"].Value = $mTreeIsoData[2].SubClassDE
		$Prop["Document Subtype"].Value = $mSelectedCls.SubClass
		$Prop["Document Subtype DE"].Value = $mSelectedCls.SubClassDE		
	}

	if($AssignClsWindow.FindName("btnSearchIEC61355")) { $AssignClsWindow.FindName("btnSearchIEC61355").IsDefault = $false}
	#$AssignClsWindow.FindName("btnOK").IsDefault = $true

	$AssignClsWindow.DialogResult = "OK"
	$AssignClsWindow.Close()
}



function mAddIEC61355Combo ([String] $_CoName, $_classes) 
{	
	$children = mGetIEC61355List -_CoName $_CoName
	If($children -eq $null) { return }
	$dsDiag.Inspect()	
	$mBreadCrumb = $AssignClsWindow.FindName("wrpIEC61355")

	$cmb = New-Object System.Windows.Controls.ComboBox
	$cmb.Name = "cmbIEC61355BreadCrumb_" + $mBreadCrumb.Children.Count.ToString();
	$cmb.DisplayMemberPath = "Name";
	$cmb.Tooltip = "Select Technical Area"
	$cmb.ItemsSource = @($children)
	$cmb.MinWidth = 140
	$cmb.HorizontalContentAlignment = "Center"
	$cmb.BorderThickness = "1,1,1,1"
	$cmb.Margin = "1,0,0,1"
	$cmb.IsDropDownOpen = $false
	$cmb.add_SelectionChanged({
			param($mSender,$e)
			mIEC61355ComboSelectionChanged -mSender $mSender
		});
	$mBreadCrumb.RegisterName($cmb.Name, $cmb) #register the name to activate later via indexed name
	$mBreadCrumb.Children.Add($cmb);

} # addCoCombo

function mAddIEC61355ComboChild ($data) 
{
	$children = @()
	$children = mGetIEC61355UsesList -mSender $data
	
	If($children.count -eq 0) { return }

	$mBreadCrumb = $AssignClsWindow.FindName("wrpIEC61355")
	$cmb = New-Object System.Windows.Controls.ComboBox
	$cmb.Name = "cmbIEC61355BreadCrumb_" + $mBreadCrumb.Children.Count.ToString();
	$cmb.DisplayMemberPath = "Name";
	$cmb.ToolTip = "Select Next Class Level"
	$cmb.ItemsSource = @($children)	
	$cmb.BorderThickness = "1,1,1,1"
	$cmb.Margin = "1,0,0,1"
	$cmb.HorizontalContentAlignment = "Center"
	$cmb.MinWidth = 140
	$cmb.IsDropDownOpen = $true
	
	$mBreadCrumb.RegisterName($cmb.Name, $cmb) #register the name to activate later via indexed name
	$mBreadCrumb.Children.Add($cmb)
	$_i = $mBreadCrumb.Children.Count
	$dsDiag.Trace("Added BreadCrumb Level: $($_i)")

	$cmb.add_SelectionChanged({
		param($mSender,$e)
		$dsDiag.Trace("next. SelectionChanged, Sender = $mSender")
		mIEC61355ComboSelectionChanged -mSender $mSender
	});

}

function mIEC61355ComboSelectionChanged ($mSender) {
	$mBreadCrumb = $AssignClsWindow.FindName("wrpIEC61355")
	$position = [int]::Parse($mSender.Name.Split('_')[1]);
	$children = $mBreadCrumb.Children.Count - 1
	while($children -gt $position )
	{
		$cmb = $mBreadCrumb.Children[$children]
		$mBreadCrumb.UnregisterName($cmb.Name) #unregister the name to correct for later addition/registration
		$mBreadCrumb.Children.Remove($mBreadCrumb.Children[$children]);
		$children--;
	}

	#write the highest level Custent Id to a text file for post-close event
	$value = $mBreadCrumb.Children[$children].SelectedItem.Name
	$value | Out-File "$($env:appdata)\Autodesk\DataStandard 2022\mIEC61355Id_$($children).txt"

	#don't continue adding children according the classification group level
	if($position -lt 3)
	{
		mAddIEC61355ComboChild -mSender $mSender.SelectedItem
	}
	else
	{
		$_data = @()
			
		$mResultAll = mGetIEC61355UsesList($mSender)
		$_data += mConvertCustentsToIEC61355Objects $mResultAll
		If($_data)
		{
			$AssignClsWindow.FindName("dataGrdIEC61355Found").ItemsSource = $_data
			$Global:NavigatedOrSearched = "Navigated"
		}
		else
		{
			$AssignClsWindow.FindName("dataGrdIEC61355Found").ItemsSource = $null
		}
	}
}

function mResetIEC61355BrdCrmb
{	
	$mBreadCrumb = $AssignClsWindow.FindName("wrpIEC61355")
	$mBreadCrumb.Children[1].SelectedIndex = -1
	$AssignClsWindow.FindName("dataGrdIEC61355Found").ItemsSource = $null
}


function mGetIEC61355List ([String] $_CoName) {
	try {
		$srchConds = New-Object autodesk.Connectivity.WebServices.SrchCond[] 2
		$srchCond = New-Object autodesk.Connectivity.WebServices.SrchCond

		$propDefs = $Global:CustentPropDefs
		$propNames = @("CustomEntityName")
		$propDefIds = @{}
		foreach($name in $propNames) {
			$propDef = $propDefs | Where-Object { $_.SysName -eq $name }
			$propDefIds[$propDef.Id] = $propDef.DispName
		}
		$srchCond.PropDefId = $propDef.Id
		$srchCond.SrchOper = 3
		$srchCond.SrchTxt = $_CoName
		$srchCond.PropTyp = [Autodesk.Connectivity.WebServices.PropertySearchType]::SingleProperty
		$srchCond.SrchRule = [Autodesk.Connectivity.WebServices.SearchRuleType]::Must
		$srchConds[0] = $srchCond

		$srchCond2 = New-Object autodesk.Connectivity.WebServices.SrchCond
		$srchCond2.PropDefId = ($Global:mAllCustentPropDefs | Where-Object { $_.DispName -eq "Standard" }).Id
		$srchCond2.SrchOper = 3 #equals
		$srchCond2.SrchTxt = $global:mActiveStandard
		$srchCond2.PropTyp = [Autodesk.Connectivity.WebServices.PropertySearchType]::SingleProperty
		$srchCond2.SrchRule = [Autodesk.Connectivity.WebServices.SearchRuleType]::Must

		$srchConds[1] = $srchCond2

		$srchSort = New-Object autodesk.Connectivity.WebServices.SrchSort
		$searchStatus = New-Object autodesk.Connectivity.WebServices.SrchStatus
		$bookmark = ""
		$_CustomEnts = $vault.CustomEntityService.FindCustomEntitiesBySearchConditions($srchConds,$null,[ref]$bookmark,[ref]$searchStatus)

		return $_CustomEnts
	}
	catch { 
		$dsDiag.Trace("!! Error in mGetIEC61355List")
	}
}

function mGetIEC61355UsesList ($mSender) {
	try {
		$dsDiag.Trace(">> mGetIEC61355UsesList started")
		$mBreadCrumb = $AssignClsWindow.FindName("wrpIEC61355")
		$_i = $mBreadCrumb.Children.Count -1
		$_CurrentCmbName = "cmbBreadCrumb_" + $mBreadCrumb.Children.Count.ToString()
		$_CurrentClsLevel = $mBreadCrumb.Children[$_i].SelectedValue.Name
		#[System.Windows.MessageBox]::Show("Currentclass: $_CurrentClsLevel and Level# is $_i")
        switch($_i -1)
		{
			0 { $mSearchFilter = "Segment"} #$UIString["Adsk.QS.ClassLevel_00"]
			1 { $mSearchFilter = "Main Group"} #$UIString["Adsk.QS.ClassLevel_01"]
			2 { $mSearchFilter = "Group"} #$UIString["Adsk.QS.ClassLevel_02"]
			3 { $mSearchFilter = "Sub Group"} #$UIString["Adsk.QS.ClassLevel_03"] 
			default { $mSearchFilter = "*"}
		}
		$_customObjects = mGetIEC61355List -_CoName $mSearchFilter
		$_Parent = $_customObjects | Where-Object { $_.Name -eq $_CurrentClsLevel }
		try {
			$links = $vault.DocumentService.GetLinksByParentIds(@($_Parent.Id),@("CUSTENT"))
			If($links)
			{
				$linkIds = @()
				$links | ForEach-Object { $linkIds += $_.ToEntId }
				$mLinkedCustObjects = $vault.CustomEntityService.GetCustomEntitiesByIds($linkIds);
				#todo: check that we need to filter the list returned
				return $mLinkedCustObjects
			}
			Else{ return}
		}
		catch {
			$dsDiag.Trace("!! Error getting links of Parent Co !!")
			return $null
		}
	}
	catch { $dsDiag.Trace("!! Error in mAddCoComboChild !!") }
}


function mGetIEC61355List2 ([String] $CustentCatName, [String] $Standard) 
{
	#the default search condition object type is custom object "Group"
	$srchConds = New-Object autodesk.Connectivity.WebServices.SrchCond[] 2
	$srchConds[0]= mCreateIEC61355SearchCond "Category Name" $CustentCatName "AND"
	$srchConds[1]= mCreateIEC61355SearchCond "Standard" $Standard "AND"

	$srchSort = New-Object autodesk.Connectivity.WebServices.SrchSort
	$searchStatus = New-Object autodesk.Connectivity.WebServices.SrchStatus
	$bookmark = ""
	$mResultAll = New-Object 'System.Collections.Generic.List[Autodesk.Connectivity.WebServices.CustEnt]'

	while(($searchStatus.TotalHits -eq 0) -or ($mResultAll.Count -lt $searchStatus.TotalHits))
	{
		$mResultPage = $vault.CustomEntityService.FindCustomEntitiesBySearchConditions($srchConds,@($srchSort),[ref]$bookmark,[ref]$searchStatus)
		If ($searchStatus.IndxStatus -ne "IndexingComplete" -or $searchStatus -eq "IndexingContent")
		{
			#check the indexing status; you might return a warning that the result bases on an incomplete index, or even return with a stop/error message, that we need to have a complete index first
			$AssignClsWindow.FindName("txtIEC61355StatusMsg").Text = $UIString["Adsk.QS.Classification_12"]
			$AssignClsWindow.FindName("txtIEC61355StatusMsg").Visibility = "Visible"
		}
		If($mResultPage.Count -ne 0)
		{
			$mResultAll.AddRange($mResultPage)
		}
		else 
		{ 
			$AssignClsWindow.FindName("txtIEC61355StatusMsg").Text = "Technical Area: No matching objects found"
			$AssignClsWindow.FindName("txtIEC61355StatusMsg").Visibility = "Visible"
			break;
		}

		#limit the search result to the first result page;
		$AssignClsWindow.FindName("txtIEC61355StatusMsg").Text = "$($CustentCatName) returns more objects than paging size allows."
		$AssignClsWindow.FindName("txtIEC61355StatusMsg").Visibility = "Visible"
		break; #limit the search result to the first result page; page scrolling not implemented in this snippet release
	}
	
	return mConvertCustentsToIEC61355Objects $mResultAll

}

function mGetIEC61355UsesList2 ([String] $CustomObjectId)
{
	$_Parent = ($vault.CustomEntityService.GetCustomEntitiesByIds(@($CustomObjectId)))[0]

	try {
		$links = $vault.DocumentService.GetLinksByParentIds(@($_Parent.Id),@("CUSTENT"))
		If($links)
		{
			$linkIds = @()
			$links | ForEach-Object { $linkIds += $_.ToEntId }
			$mLinkedCustObjects = $vault.CustomEntityService.GetCustomEntitiesByIds($linkIds);
			#todo: check that we need to filter the list returned
			return mConvertCustentsToIEC61355Objects $mLinkedCustObjects
		}
		Else{ return}
	}
	catch {
		$dsDiag.Trace("!! Error getting links of Parent Co !!")
		return $null
	}
}

function mConvertCustentsToIEC61355Objects($Custents)
{
		If($Custents.Count -lt 1){
			Return
		}
		Else{
			$AssignClsWindow.FindName("txtIEC61355StatusMsg").Visibility = "Collapsed"
			$mResultAll = $Custents
		}
		
		# 	retrieve all properties of the COs found
		$_data = @()
		#derive data set from result do display; items have system properties like number, title, but others require to query the entity properties
		$mResultItemIds = @()
		$mResultAll | ForEach-Object { $mResultItemIds += $_.Id}
		$mPropDefs = @() #to be consumed by GetProperties
		$mPropDict = @{} #to be leveraged reading property by Name instead of Def.Id
		$mDefId += ($Global:CustentPropDefs | Where-Object { $_.DispName -eq "Name"}).Id
		$mPropDefs += $mDefID
		$mPropDict.Add("Name", $mDefID)
		$mDefId = ($Global:CustentPropDefs | Where-Object { $_.DispName -eq "Code"}).Id
		$mPropDefs += $mDefID
		$mPropDict.Add("Code", $mDefID)
		$mDefId = ($Global:CustentPropDefs | Where-Object { $_.DispName -eq "Comments"}).Id
		$mPropDefs += $mDefID
		$mPropDict.Add("Comments", $mDefID)
		$mDefId = ($Global:CustentPropDefs | Where-Object { $_.DispName -eq "Term DE"}).Id
		$mPropDefs += $mDefID
		$mPropDict.Add("Term DE", $mDefID)
		$mDefId = ($Global:CustentPropDefs | Where-Object { $_.DispName -eq "Comments DE"}).Id
		$mPropDefs += $mDefID
		$mPropDict.Add("Comments DE",$mDefID)

		$mPropInst = $vault.PropertyService.GetProperties("CUSTENT", $mResultItemIds, $mPropDefs)

		#build the table to display items with properties

		foreach($item in $mResultAll)
		{
			$row = New-Object IEC61355Data
			$row.Id = $item.Id
			$row.SubClass = $item.Name
			$row.Code = ($mPropInst | Where-Object { $_.EntityId -eq $item.Id -and $_.PropDefId -eq $mPropDict["Code"]}).Val
			$row.Example = ($mPropInst | Where-Object { $_.EntityId -eq $item.Id -and $_.PropDefId -eq $mPropDict["Comments"]}).Val
			$row.SubClassDE = ($mPropInst | Where-Object { $_.EntityId -eq $item.Id -and $_.PropDefId -eq $mPropDict["Term DE"]}).Val
			$row.ExampleDE = ($mPropInst | Where-Object { $_.EntityId -eq $item.Id -and $_.PropDefId -eq $mPropDict["Comments DE"]}).Val
			$row.PathCode = "[Tree]"
			$_data += $row
		}
		return $_data
}