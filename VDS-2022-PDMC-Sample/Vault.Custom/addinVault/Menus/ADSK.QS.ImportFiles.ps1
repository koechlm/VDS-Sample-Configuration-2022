#=============================================================================
# PowerShell script sample for Vault Data Standard                            
# Reserve a range of File Numbers from Autodesk Vault                         
#                                                                             
# Copyright (c) Autodesk - All rights reserved.                               
#                                                                             
# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER   
# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.  
#=============================================================================

$dialog = $dsCommands.GetCreateFolderDialog(1)
$xamlFile = New-Object CreateObject.WPF.XamlFile "ImportFileXaml", "%ProgramData%\Autodesk\Vault 2022\Extensions\DataStandard\Vault.Custom\Configuration\ADSK.QS.FileImport.xaml"
$dialog.XamlFile = $xamlFile

$result = $dialog.Execute()
#$dsDiag.Trace($result)

