Clear-Host

#$exPolicy = Get-ExecutionPolicy

#Write-Host "Current execution policy is $exPolicy, will be changed to RemoteSigned. Will be reverted once the execution of script is complete" -ForegroundColor Cyan

#Set-ExecutionPolicy RemoteSigned -Force 


function Save-Project ($fileName, [xml]$xml) 
{ 
	$indent=4
    $StringWriter = New-Object System.IO.StringWriter 
    $XmlWriter = New-Object System.XMl.XmlTextWriter $StringWriter 
    $xmlWriter.Formatting = "indented" 
    $xmlWriter.Indentation = $Indent 
    $xml.WriteContentTo($XmlWriter) 
    $XmlWriter.Flush() 
    $StringWriter.Flush() 
    
    $xml = [xml]$StringWriter.ToString() 
	$xml.Save($fileName)
	
    Write-Host "Saving... $fileName" -ForegroundColor Green
	
}

# $sourcePath = "C:\Users\dbudhwan\Documents\Visual Studio 2010\Projects\VCIMailHelper"

Write-Host "Getting for solution files under... $sourcePath"

# add tfs team foundation utility path (ts) to the local environment 
# this path will be used to checkout files
$gat_path = ";C:\Program Files (x86)\Microsoft Visual Studio 10.0\Common7\IDE;"
$env:Path = $env:Path + $gat_path


$csprojFiles = Get-ChildItem . -recurse -filter "*.csproj" 
foreach ($project in $csprojFiles)
{
    $csprojXml = [xml](Get-Content $project.FullName)
    $toolsVersion = $csprojXml.Project.GetAttributeNode("ToolsVersion")
    $projectGroups = $csprojXml.Project.PropertyGroup
	
	Write-Host "Converting... $project.FullName" 

    [bool] $isProjectXmlUpdated = $false

    foreach ($projectGroup in $projectGroups)
    {
        # Write-Host $projectGroup.OuterXML            
            
        # if TargetFrameworkVersion is not already 4.5
        # Upgrade TargetFrameworkVersion "4.5"
        $targetFrameworkElements = $projectGroup.GetElementsByTagName("TargetFrameworkVersion")
        $oldToolsVersion = "4.0"
        foreach($targetFrameworkElement in $targetFrameworkElements)
        {
            Write-Host "Updating framework version to 4.5... " -ForegroundColor Cyan
			
            $oldToolsVersion = $targetFrameworkElement.InnerText
            $targetFrameworkElement.InnerText = "v4.5"
			[bool] $isProjectXmlUpdated = $true
            break
        }
		
		#For Framework 4.5, TargetFrameworkProfile element inner text is blank 
		$targetFrameworkProfiles = $projectGroup.GetElementsByTagName("TargetFrameworkProfile")
        foreach($targetFrameworkProfile in $targetFrameworkProfiles)
        {
            Write-Host "Updating framework version to 4.5... " -ForegroundColor Cyan
			
            $targetFrameworkProfile.InnerText = ""
			[bool] $isProjectXmlUpdated = $true
            break
        }
		
		# Add Prefer32Bit tag to PropertyGroup element whose Condition attribute is either Debug or Release 		
		if($projectGroup.Condition -ne $null)
		{
			$Prefer32Bit = $projectGroup.GetElementsByTagName("Prefer32Bit")
			
			Write-Host "Check whether Prefer32Bit tag is available " -ForegroundColor Cyan
			if($Prefer32Bit.Count -eq 0)
			{
				
				$club = $csprojXml.CreateElement('Prefer32Bit', $csprojXml.DocumentElement.NamespaceURI)
				$club.InnerText = "false"
				$projectGroup.AppendChild($club)
				Write-Host "Prefer32Bit Tag... is Added " -ForegroundColor Green
				[bool] $isProjectXmlUpdated = $true
			}
			Write-Host "Adding Prefer32Bit Tag... " -ForegroundColor Cyan
		}
    }
	
	# update xml file
	if($isProjectXmlUpdated)
	{
	
		# Checkout file for modify
		tf.exe checkout $project.FullName
		
	    # save xml content back to project file
	    Save-Project $project.FullName $csprojXml
	}
}

$configFiles = Get-ChildItem . -recurse -filter "App.config" 
foreach ($configFile in $configFiles)
{
    $configFileXml = [xml](Get-Content $configFile.FullName)
    $supportedRuntimes = $configFileXml.configuration.startup.supportedRuntime
	
	Write-Host "Converting... $configFile.FullName" 

    [bool] $isConfigXmlUpdated = $false

    foreach ($supportedRuntime in $supportedRuntimes)
    { 
		Write-Host "Upgrating version to 4.5... $configFile.FullName"  -ForegroundColor Green
		$supportedRuntime.SetAttribute("sku",".NETFramework,Version=v4.5")
		[bool] $isConfigXmlUpdated = $true
		break       	
    }
	
	# update xml file
	if($isConfigXmlUpdated)
	{
	
		# Checkout file for modify
		tf.exe checkout $configFile.FullName
		
	    # save xml content back to project file
	    Save-Project $configFile.FullName $configFileXml
	}
}

Write-Host "Checking out resource files... "
$files = Get-ChildItem . -recurse -filter "*.resx" 
foreach ($file in $files)
{
    # Checkout file for modify
	tf.exe checkout $file.FullName
}

Write-Host "Checking out Desinger files... "
$files = Get-ChildItem . -recurse -filter "*.Designer.cs" 
foreach ($file in $files)
{
    # Checkout file for modify
	tf.exe checkout $file.FullName
}

Write-Host "Checking out Settings files... "
$files = Get-ChildItem . -recurse -filter "Settings.settings" 
foreach ($file in $files)
{
    # Checkout file for modify
	tf.exe checkout $file.FullName
}


Write-Host "Completed upgrade of the project files..."

#Set-ExecutionPolicy $exPolicy -Force