$folderId=$vaultContext.CurrentSelectionSet[0].Id
$vaultContext.ForceRefresh = $true
$dialog = $dsCommands.GetCreateFolderDialog($folderId)

#override the default dialog file assigned
$xamlFile = New-Object CreateObject.WPF.XamlFile "ADSK.QS.Folder.xaml", "C:\ProgramData\Autodesk\Vault 2022\Extensions\DataStandard\Vault.Custom\Configuration\ADSK.QS.Folder.xaml"
$dialog.XamlFile = $xamlFile

$result = $dialog.Execute()
#$dsDiag.Trace($result)

if($result)
{
	#new folder can be found in $dialog.CurrentFolder
	$folder = $vault.DocumentService.GetFolderById($folderId)
	$path=$folder.FullName+"/"+$dialog.CurrentFolder.Name

	#apply project template
	$UIString = mGetUIStrings
	$NewFolder = $vault.DocumentService.GetFolderByPath($path)

	if($NewFolder.Cat.Catname -ne $UIString["CAT5"])
	{
		#the new folder is the targetfolder to create subfolders, the source folder is the template to be used
		$TempFolderName = "$/Templates/Folders/" + $NewFolder.Cat.Catname
		$tempFolder = $vault.DocumentService.GetFolderByPath($TempFolderName)
		mRecursivelyCreateFolders -targetFolder $NewFolder -sourceFolder $tempFolder
	}
	
	#region TC Links
	#$NewFolder = $vault.DocumentService.GetFolderByPath($path)
	If ($NewFolder.Cat.Catname -eq $UIString["CAT6"])
	{
		#Create the TC Link
		$TCLink = Adsk.CreateTcFolderLink $path
		#Save TC Link in UDP
		mUpdateFldrProperties $NewFolder.Id "ThinClient Link" $TCLink	
	}
	#endregion TC Links

	#region create_links
	try
	{
		$companyID = Get-Content "$($env:appdata)\Autodesk\DataStandard 2022\mOrganisationId.txt"
		$contactID = Get-Content "$($env:appdata)\Autodesk\DataStandard 2022\mPersonId.txt"
		#if($companyID -ne "") { $link1 = $vault.DocumentService.AddLink($companyID,"FLDR",$dialog.CurrentFolder.Id,"Organisation->Folder") }
		if($companyID -ne $null) { $link2 = $vault.DocumentService.AddLink($dialog.CurrentFolder.Id,"CUSTENT",$companyID,"Folder->Organisation") }
		#if($contactID -ne "") { $link3 = $vault.DocumentService.AddLink($contactID,"FLDR",$dialog.CurrentFolder.Id,"Person->Folder") }
		if($contactID -ne $null) { $link3 = $vault.DocumentService.AddLink($dialog.CurrentFolder.Id,"CUSTENT",$contactID,"Folder->Person") }
	}
	catch
	{
		#$dsDiag.Trace("CreateFolder.ps1 - AddLink command failed") 
	}
	finally {
		#in any case don't use the last entry twice...
		$null | Out-File "$($env:appdata)\Autodesk\DataStandard 2022\mOrganisationId.txt"
		$null | Out-File "$($env:appdata)\Autodesk\DataStandard 2022\mPersonId.txt"
	}
	#endregion
	
	$selectionId = [Autodesk.Connectivity.Explorer.Extensibility.SelectionTypeId]::Folder
	$location = New-Object Autodesk.Connectivity.Explorer.Extensibility.LocationContext $selectionId, $path
	$vaultContext.GoToLocation = $location
}
Else
{
	#in case cancel / close Window (Window button X), remove last entries as well...
	$null | Out-File "$($env:appdata)\Autodesk\DataStandard 2022\mOrganisationId.txt"
	$null | Out-File "$($env:appdata)\Autodesk\DataStandard 2022\mPersonId.txt"
}