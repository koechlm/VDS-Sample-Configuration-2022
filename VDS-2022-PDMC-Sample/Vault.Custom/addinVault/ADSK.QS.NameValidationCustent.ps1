function InitializeCustentNameValidation
{
    $Prop["_CustomObjectName"].CustomValidation = { ValidateCustentName }
}

function ValidateCustentName
{
    #in case a numbering scheme is active, the validation is positiv, but not for all categories
    if(-not $dsWindow.FindName("DSNumSchmsCtrl").NumSchmFieldsEmpty)
	{
		return $true
    }

    #to check hand-typed custent names, a Vault search is required to check for existing names as the user types
    if($Prop["_CustomObjectName"].Value)
	{
        #separate the search into a distinct function "mFindCustent"
		$mCustentExist = mFindCustent $Prop["_CustomObjectName"].Value $Prop["_Category"].Value

        if($mCustentExist)
		{
			$dsWindow.FindName("CUSTOMOBJECTNAME").ToolTip = "A custom object with this name exists."
			$dsWindow.FindName("CUSTOMOBJECTNAME").BackGround = "#7FFF0000"
			return $false
		}
		Else
		{
			$dsWindow.FindName("CUSTOMOBJECTNAME").ToolTip = $null
			$dsWindow.FindName("CUSTOMOBJECTNAME").BackGround = "#FFFFFFFF"
			return $true
		}
	}
	else
	{
		$Property.CustomValidationErrorMessage = "Custom Object name must not be empty."
		$dsWindow.FindName("CUSTOMOBJECTNAME").ToolTip = "Custom Object name must not be empty."
		$dsWindow.FindName("CUSTOMOBJECTNAME").Border = "Red"
		return $false
	}
}

function mFindCustent($CustentName, $Category)
{
	#build the search conditions first
	$mSrchCndtns = @()
	$propDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("CUSTENT")
		
	#condition 1
	$propDef = $propDefs | Where-Object { $_.DispName -eq "Name" }
	$srchCond = New-Object autodesk.Connectivity.WebServices.SrchCond
	$srchCond.PropDefId = $propDef.Id
	$srchCond.SrchOper = 3
	$srchCond.SrchTxt = $CustentName
	$srchCond.PropTyp = [Autodesk.Connectivity.WebServices.PropertySearchType]::SingleProperty
	$srchCond.SrchRule = [Autodesk.Connectivity.WebServices.SearchRuleType]::Must
	#add condition 1
	$mSrchCndtns += $srchCond
		
	#condition 2
	$propDef = $propDefs | Where-Object { $_.DispName -eq "Category Name" }
	$srchCond = New-Object autodesk.Connectivity.WebServices.SrchCond
	$srchCond.PropDefId = $propDef.Id
	$srchCond.SrchOper = 3
	$srchCond.SrchTxt = $Category
	$srchCond.PropTyp = [Autodesk.Connectivity.WebServices.PropertySearchType]::SingleProperty
	$srchCond.SrchRule = [Autodesk.Connectivity.WebServices.SearchRuleType]::Must
	#add condition 2
	$mSrchCndtns += $srchCond

	$srchSort = New-Object autodesk.Connectivity.WebServices.SrchSort
	$searchStatus = New-Object autodesk.Connectivity.WebServices.SrchStatus
	$bookmark = ""     
	$mResultAll = New-Object 'System.Collections.Generic.List[Autodesk.Connectivity.WebServices.CustEnt]'
	
	while(($searchStatus.TotalHits -eq 0) -or ($mResultAll.Count -lt $searchStatus.TotalHits))
	{
			$mResultPage = $vault.CustomEntityService.FindCustomEntitiesBySearchConditions($mSrchCndtns,@($srchSort),[ref]$bookmark,[ref]$searchStatus)
			
		If ($searchStatus.IndxStatus -ne "IndexingComplete" -or $searchStatus -eq "IndexingContent")
		{
			#check the indexing status; you might return a warning that the result bases on an incomplete index, or even return with a stop/error message, that we need to have a complete index first
		}
		if($mResultPage.Count -ne 0)
		{
			$mResultAll.AddRange($mResultPage)
			return $true
		}
		else { return $false }
				
		break; #limit the search result to the first result page;
	}
} 