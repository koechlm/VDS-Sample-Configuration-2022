
Add-Type @'
public class myBom
{
	public int Position;
	public string PartNumber;
	public string ComponentType;
	public float Quantity;
	public string Name;
	public byte[] Thumbnail;
	public string Title;
	public string Description;
	public string Material;
}
'@

function GetFileBOM($fileID)
{
	#Get Thumbnail PropertyDefinition 
	$propDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId('FILE')
	$thumbnailPropDef = $propDefs | Where-Object {$_.SysName -eq 'Thumbnail'}

	$dsDiag.Trace(">> Starting GetFileBOM($fileID)")
	$bom = $vault.DocumentService.GetBOMByFileId($fileID)
	$cldIds =@()
	$_ExternalIds = @()
	$bom.InstArray | Where-Object { $_.ParId -eq 0 } | ForEach-Object { 
		$CldId = $_.CldId
		$comp = $bom.CompArray | Where-Object { $_.Id -eq $CldId }
		#region workaround to eliminate virtual components
		If ($comp.CompTyp -ne "Virtual"){
			$cldIds += $comp.XRefId
			$Global:_mContainsVirtual = $false
			$_ExternalIds += $comp.Id
			$dsWindow.FindName("txtBlck_Notification").Visibility = "Collapsed"
		}
		Else { 
			$Global:_mContainsVirtual = $true 
			$dsWindow.FindName("txtBlck_Notification").Visibility = "Visible"
			$dsWindow.FindName("txtBlck_Notification").Text = $UIString["MSDCE_CAD-BOM01"]
		}
		#endregion
	}
	$dsDiag.Trace("   cldIds: "+$cldIds.Count)
	$bomItems = @()
	if($cldIds.Count -gt 0) #the file contains BOM information, so continue
	{
		$CldBoms = $vault.DocumentService.GetBOMByFileIds($cldIds)
		$schm = $bom.SchmArray | Where-Object { $_.SchmTyp -eq "Structured" }
		$cldBomCounter = 0
	#region workaround to eliminate virtual components
		$_BomInstArray = $bom.InstArray | Where-Object { ($_.ParId -eq 0)}

		$_BomInstArray = $_BomInstArray | Where-Object { ( $_ExternalIds -contains $_.Id)}

		$_BomInstArray | ForEach-Object {
		#$bom.InstArray | Where-Object { ($_.ParId -eq 0)} | ForEach-Object {
	#endregion
			$bomItem = New-Object myBom
			$CldId = $_.CldId
			$bomItem.Quantity = $_.Quant
			$comp = $bom.CompArray | Where-Object { $_.Id -eq $CldId }

			$occur = $bom.SchmOccArray | Where-Object { $_.SchmId -eq $schm.Id -and $_.CompId -eq $CldId }
			$bomItem.Position = $occur.DtlId

			$cldBom = $CldBoms[$cldBomCounter++]
			$bomItem.Name = $cldBom.CompArray[0].Name
			$bomItem.ComponentType = $cldBom.CompArray[0].CompTyp
			$PropPartNumber = $cldBom.PropArray | Where-Object { $_.dispName -eq "Part Number"}
			$prop = $cldBom.CompAttrArray | Where-Object { $_.PropId -eq $PropPartNumber.Id}
			$bomItem.PartNumber = $prop.Val
			$bomItems += $bomItem
			#add Inventor default BOM columns
			$thumbnailProp = $vault.PropertyService.GetProperties('FILE', @($cldIds[$cldBomCounter - 1]), @($thumbnailPropDef.Id))[0]
			$bomItem.Thumbnail = $thumbnailProp.Val
			$m_Prop = $cldBom.PropArray | Where-Object { $_.dispName -eq "Title"}
			$prop = $cldBom.CompAttrArray | Where-Object { $_.PropId -eq $m_Prop.Id}
			$bomItem.Title = $prop.Val
			$m_Prop = $cldBom.PropArray | Where-Object { $_.dispName -eq "Description"}
			$prop = $cldBom.CompAttrArray | Where-Object { $_.PropId -eq $m_Prop.Id}
			$bomItem.Description = $prop.Val
			$m_Prop = $cldBom.PropArray | Where-Object { $_.dispName -eq "Material"}
			$prop = $cldBom.CompAttrArray | Where-Object { $_.PropId -eq $m_Prop.Id}
			$bomItem.Material = $prop.Val
		}
	}
	Else #the file does not contain BOM information - notify the user
	{
		$dsWindow.FindName("txtBlck_Notification").Visibility = "Visible"
		$dsWindow.FindName("txtBlck_Notification").Text = $UIString["MSDCE_CAD-BOM02"]
	}
	$dsDiag.Trace("<< Ending GetFileBOM with $($bomItems.Count) items found")
	return $bomItems
}