#region disclaimer =============================================================================
# PowerShell script sample for Vault Data Standard
#			 Autodesk Vault - VDS-PDMC-Sample 2022
# This sample is based on VDS 2022 RTM and adds functionality and rules
#
# Copyright (c) Autodesk - All rights reserved.
#
# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.
#endregion =============================================================================

#region - version history
#Version Info - VDS-PDMC-Sample Revision Management 2022.0.1
	# deleted unused function, fixed display of customer approval grid

# Version Info - VDS-PDMC-Sample Revision Management 2022.0.0
	# initial version
#endregion

function InvertReadOnly
{
	if ($Prop["_ReadOnly"].Value){
		return $false
	}
	else{
		return $true
	}
}

function InitializeRevisionValidation
{
	#set the display state of XAML controls
	$dsWindow.FindName("grdCustomerApproval").Visibility = "Collapsed"

	#Inventor and AutoCAD Drawings initialize custom property validation only
	if(@($UIString["MSDCE_CAT00"], $UIString["MSDCE_CAT01"]) -contains $Prop["_Category"].Value)
	{
		#set the display state of XAML controls		
		if($Prop["_XLTN_CUSTAPPRVLREQ"].Value -eq $true)
		{
			$dsWindow.FindName("grdCustomerApproval").Visibility = "Visible"
		}
		else
		{
			$dsWindow.FindName("grdCustomerApproval").Visibility = "Collapsed"
		}

		#don't enforce anything for new files
		if($Prop["_CreateMode"].Value -eq $true)
		{
				if($Prop["_XLTN_CHECKEDBY"]) {
					$Prop["_XLTN_CHECKEDBY"].CustomValidation = { $true }
				}
				if($Prop["_XLTN_CHECKEDDATE"]){
					$Prop["_XLTN_CHECKEDDATE"].CustomValidation = { $true }
				}
				if($Prop["_XLTN_ENGAPPRVDBY"]){
					$Prop["_XLTN_ENGAPPRVDBY"].CustomValidation = { $true }
				}
				if($Prop["_XLTN_ENGAPPRVDDATE"]){
					$Prop["_XLTN_ENGAPPRVDDATE"].CustomValidation = { $true }
				}
				if($Prop["_XLTN_CHANGEDESCR"]){
					$Prop["_XLTN_CHANGEDESCR"].CustomValidation = { $true }
				}
		}

		#enforce revision properties dependent on current state
		if($Prop["_EditMode"].Value -eq $true)
		{
			#Work in Progress or Quick-Change
			if(@($UIString["Adsk.QS.RevTab_05"], $UIString["Adsk.QS.RevTab_04"]) -contains $Prop["_XLTN_STATE"].Value)
			{
				if($Prop["_XLTN_DOCCHCKREQ"])
				{
					if($Prop["_XLTN_DOCCHCKREQ"].Value -eq "True")
					{
						if($Prop["_XLTN_CHECKEDBY"]) 
						{
							$Prop["_XLTN_CHECKEDBY"].CustomValidation = { ValidateRevisionField($Prop["_XLTN_CHECKEDBY"]) }
						}
					}
				}
				
				if($Prop["_XLTN_CHECKEDDATE"]){
					$Prop["_XLTN_CHECKEDDATE"].CustomValidation = { $true }
				}
				if($Prop["_XLTN_ENGAPPRVDBY"]){
					$Prop["_XLTN_ENGAPPRVDBY"].CustomValidation = { $true }
				}
				if($Prop["_XLTN_ENGAPPRVDDATE"]){
					$Prop["_XLTN_ENGAPPRVDDATE"].CustomValidation = { $true }
				}
				if($Prop["_XLTN_CHANGEDESCR"]){
					$Prop["_XLTN_CHANGEDESCR"].CustomValidation = { $true }
				}
			} #Work in Progress or Quick-Change

			#For Review
			if(@($UIString["Adsk.QS.RevTab_03"]) -contains $Prop["_XLTN_STATE"].Value)
			{
				if($Prop["_XLTN_DOCCHCKREQ"])
				{
					if($Prop["_XLTN_DOCCHCKREQ"].Value -eq "True")
					{
						if($Prop["_XLTN_CHECKEDBY"]) {
							$Prop["_XLTN_CHECKEDBY"].CustomValidation = { ValidateRevisionField($Prop["_XLTN_CHECKEDBY"]) }
						}
						if($Prop["_XLTN_CHECKEDDATE"])
						{
							$Prop["_XLTN_CHECKEDDATE"].CustomValidation = { ValidateRevisionField($Prop["_XLTN_CHECKEDDATE"]) }
						}
					}
				}
				if($Prop["_XLTN_ENGAPPRVDBY"]){
					$Prop["_XLTN_ENGAPPRVDBY"].CustomValidation = { ValidateRevisionField($Prop["_XLTN_ENGAPPRVDBY"]) }
				}
				if($Prop["_XLTN_ENGAPPRVDDATE"]){
					$Prop["_XLTN_ENGAPPRVDDATE"].CustomValidation = { ValidateRevisionField($Prop["_XLTN_ENGAPPRVDDATE"]) }
				}
				if($Prop["_XLTN_CHANGEDESCR"]){
					$Prop["_XLTN_CHANGEDESCR"].CustomValidation = { ValidateRevisionField($Prop["_XLTN_CHANGEDESCR"]) }
				}
			}# For Review
		}

	}#drawing categories

}

function ValidateRevisionField($mProp)
{
	If ($Prop["_CreateMode"].Value -eq $true)
    {
        return $true
    }

	If ($Prop["_EditMode"].Value -eq $true)
	{		
		$dsDiag.Trace("...EditMode...")
		
		if ($mProp.Value -eq "" -OR $mProp.Value -eq $null)
		{
			$dsDiag.Trace(" '$($mProp)'...no Value: returning false<<")
			return $false
		}
		else
		{
			#workaround VDS AutoCAD Date Issue (2022.1)
			$tempDateTime = Get-Date -Year "2022" -Month "01" -Day "01" -Hour "00" -Minute "00" -Second "00"
			if($mProp.Value -eq $tempDateTime.ToString()) 
			{ 
				$mProp.CustomValidationErrorMessage = "Date 2022-01-01 00:00:00 provided by VDS for AutoCAD is not allowed (VDS Acad date issue workaround)"
				return $false
			}

			$dsDiag.Trace(" '$($mProp)'...has Value: returning true<<")
			return $true
		}
	}#edit mode

}#function

