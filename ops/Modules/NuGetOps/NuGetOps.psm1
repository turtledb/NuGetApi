$RepoRoot = (Convert-Path "$PsScriptRoot\..\..\..")
Export-ModuleMember -Variable RepoRoot

# Extract Ops NuGetOpsVersion
$NuGetProps = [xml](cat (Join-Path $RepoRoot "build\NuGet.props"))
$NuGetOpsVersion = New-Object System.Version "$($NuGetProps.Project.PropertyGroup.MajorVersion).$($NuGetProps.Project.PropertyGroup.MinorVersion)"
Export-ModuleMember -Variable NuGetOpsVersion

# Find the Azure SDK
$SDKParent = "$env:ProgramFiles\Microsoft SDKs\Windows Azure\.NET SDK"
$AzureSDKRoot = $null;
if(Test-Path $SDKParent) {
	# Pick the latest
	$AzureSDKRoot = (dir $SDKParent | sort Name -desc | select -first 1).FullName
}
Export-ModuleMember -Variable AzureSDKRoot

if(!$AzureSDKRoot) {
	Write-Warning "Couldn't find the Azure SDK. Some commands may not work."
} else {
	Write-Host "Using Azure SDK at: $AzureSDKRoot"
}

if(!(Get-Command Get-AzureAccount -ErrorAction SilentlyContinue)) {
	throw "The NuGet Operations Module requires that you have the Azure PowerShell Module installed and imported (Import-NuGetOps will import the Azure module automatically, if it is installed)."
}

$accounts = @(Get-AzureAccount)
if($accounts.Length -eq 0) {
	Write-Warning "No Azure Accounts found. Run Add-AzureAccount to configure your Azure account."
}

# Locate the NuGetInternal repository
# Check the environment Variable
$NuGetInternalRoot = $env:NUGET_INTERNAL_REPO
if(!$NuGetInternalRoot) {
	# Try to find it
	$DefaultInternalRepo = Join-Path (Split-Path -Parent $RepoRoot) "NuGetInternal"
	if(Test-Path "$DefaultInternalRepo\Environments.xml") {
		$NuGetInternalRoot = $DefaultInternalRepo
	} else {
		Write-Warning "Could not find NuGetInternal repository. Use the NUGET_INTERNAL_REPO environment variable to set the location of this repository if it is not in the default location of: $DefaultInternalRepo"
		Write-Warning "The repository must have the following files in the root: Environments.xml and Subscriptions.xml"
		Write-Warning "Some commands may not work without this path"
	}
}

# If we have the internal repo, load the Environments list
if($NuGetInternalRoot) {
	$ServiceModel = & "$PsScriptRoot\Private\Load-Environments.ps1" $NuGetInternalRoot
	$Environments = $ServiceModel.Environments
	$Subscriptions = $ServiceModel.Subscriptions
	Export-ModuleMember -Variable ServiceModel,Environments,Subscriptions
}

# # Try to load V3 Environments
# $Global:ServiceModel = Get-V3Environments -NuGetOpsDefinition $NuGetOpsDefinition
# if(!$Global:ServiceModel) {
# 	$Global:ServiceModel = Get-V2Environments -NuGetOpsDefinition $NuGetOpsDefinition
# }
# $Global:Environments = $ServiceModel.Environments
# $Global:Subscriptions = $ServiceModel.Subscriptions

# function Get-Environment([switch]$ListAvailable) {
# 	if($ListAvailable) {
# 		@($Environments.Keys | ForEach-Object { 
# 			if(Test-Environment $_) {
# 				"* $_"
# 			} else {
# 				"  $_"
# 			}
# 		})
# 	} else {
# 		if(!$CurrentEnvironment) {
# 			$null;
# 		} else {
# 			$CurrentEnvironment.Name
# 		}
# 	}
# }
# Export-ModuleMember -Function Get-Environment

# function Test-Environment([Parameter(Mandatory=$true)][String]$Environment, [Switch]$Exists) {
# 	if($Exists) {
# 		return $Environments.ContainsKey($Environment)
# 	} else {
# 		[String]::Equals((Get-Environment), $Environment, "OrdinalIgnoreCase");
# 	}
# }
# Export-ModuleMember -Function Test-Environment

# function _IsProduction {
# 	$CurrentEnvironment -and ($CurrentEnvironment.Protected -eq "true")
# }

# function _RefreshGitColors {
# 	$global:GitPromptSettings = New-Object PSObject -Property @{
# 	    DefaultForegroundColor    = $Host.UI.RawUI.ForegroundColor
	
# 	    BeforeText                = ' ['
# 	    BeforeForegroundColor     = [ConsoleColor]::Yellow
# 	    BeforeBackgroundColor     = $Host.UI.RawUI.BackgroundColor    
# 	    DelimText                 = ' |'
# 	    DelimForegroundColor      = [ConsoleColor]::Yellow
# 	    DelimBackgroundColor      = $Host.UI.RawUI.BackgroundColor
	    
# 	    AfterText                 = ']'
# 	    AfterForegroundColor      = [ConsoleColor]::Yellow
# 	    AfterBackgroundColor      = $Host.UI.RawUI.BackgroundColor
	    
# 	    BranchForegroundColor       = [ConsoleColor]::Cyan
# 	    BranchBackgroundColor       = $Host.UI.RawUI.BackgroundColor
# 	    BranchAheadForegroundColor  = [ConsoleColor]::Green
# 	    BranchAheadBackgroundColor  = $Host.UI.RawUI.BackgroundColor
# 	    BranchBehindForegroundColor = [ConsoleColor]::Red
# 	    BranchBehindBackgroundColor = $Host.UI.RawUI.BackgroundColor
# 	    BranchBehindAndAheadForegroundColor = [ConsoleColor]::Yellow
# 	    BranchBehindAndAheadBackgroundColor = $Host.UI.RawUI.BackgroundColor
	    
# 	    BeforeIndexText           = ""
# 	    BeforeIndexForegroundColor= [ConsoleColor]::DarkGreen
# 	    BeforeIndexBackgroundColor= $Host.UI.RawUI.BackgroundColor
	    
# 	    IndexForegroundColor      = [ConsoleColor]::DarkGreen
# 	    IndexBackgroundColor      = $Host.UI.RawUI.BackgroundColor
	    
# 	    WorkingForegroundColor    = [ConsoleColor]::DarkRed
# 	    WorkingBackgroundColor    = $Host.UI.RawUI.BackgroundColor
	    
# 	    UntrackedText             = ' !'
# 	    UntrackedForegroundColor  = [ConsoleColor]::DarkRed
# 	    UntrackedBackgroundColor  = $Host.UI.RawUI.BackgroundColor
	    
# 	    ShowStatusWhenZero        = $true
	    
# 	    AutoRefreshIndex          = $true
	
# 	    EnablePromptStatus        = !$GitMissing
# 	    EnableFileStatus          = $true
# 	    RepositoriesInWhichToDisableFileStatus = @( ) # Array of repository paths
	
# 	    Debug                     = $false
# 	}
# 	if(_IsProduction) {
# 		$GitPromptSettings.WorkingForegroundColor = [ConsoleColor]::Yellow
# 		$GitPromptSettings.UntrackedForegroundColor = [ConsoleColor]::Yellow
# 	    	$GitPromptSettings.IndexForegroundColor = [ConsoleColor]::Cyan
# 	}
# }

# function env([string]$Name) {
# 	if([String]::IsNullOrEmpty($Name)) {
# 		Get-Environment -ListAvailable
# 	} else {
# 		Set-Environment -Name $Name
# 	}
# }
# Export-ModuleMember -Function env

# $Global:GalOpsExe = join-path $GalOpsRoot "bin\Debug\galops.exe"
# if(!(Test-Path $GalOpsExe)) {
# 	$answer = Read-Host "Gallery ops exe not built. Build it now? (Y/n)"
# 	if([String]::IsNullOrEmpty($answer) -or $answer.Equals("y", "OrdinalIgnoreCase") -or $answer.Equals("yes", "OrdinalIgnoreCase")) {
# 		pushd $RepoRoot
# 		Write-Host "Building GalOps.exe..."
# 		& msbuild /v:m | Out-Host
# 		popd
# 	} else {
# 		Write-Host -Background Yellow -Foreground Black "Warning: Do not execute gallery ops tasks until you have built the GalOps.exe executable"
# 	}
# }

# # Load Private Functions
# dir $PsScriptRoot\Private\*.ps1 | foreach {
# 	. $_
# }

# # Load Public Functions
# dir $PsScriptRoot\Public\*.ps1 | foreach {
# 	. $_
# 	Export-ModuleMember -Function "$([IO.Path]::GetFileNameWithoutExtension($_.Name))"
# }



# #Clear-Host
# Write-Host -BackgroundColor Blue -ForegroundColor White @"
#  _____     _____     _      _____ _____ _____ 
# |   | |_ _|   __|___| |    |     |     |   __|
# | | | | | |  |  |  | - |   |  |  |  |__|__   |
# |_|___|___|_____|___|_|    |_____|__|  |_____|
                                              
# "@
# Write-Host -ForegroundColor Black -BackgroundColor Yellow "Welcome to the NuGet Operations Console (v$NuGetOpsVersion)"

# if($Environments.Count -eq 0) {
# 	Write-Warning "No environments are available, the console will not function correctly.`r`nSee https://github.com/NuGet/NuGetOperations/wiki/Setting-up-the-Operations-Console for more info"
# }
# if(!(Test-Path "$env:ProgramFiles\Microsoft SDKs\Windows Azure\.NET SDK\")) {
# 	Write-Warning "Couldn't find the Azure .NET SDK. Some operations may not work without it."
# }

# function Write-NuGetOpsPrompt() {
# 	$envName = "<NONE>"
# 	if($CurrentEnvironment) { $env = $CurrentEnvironment.Name; }
# 	$host.UI.RawUI.WindowTitle = "NuGet Operations Console v$NuGetOpsVersion [Environment: $env]"

# 	Write-Host -noNewLine "$(Get-Location)"
	
# 	$realLASTEXITCODE = $LASTEXITCODE

# 	# Reset color, which can be messed up by Enable-GitColors
# 	$Host.UI.RawUI.ForegroundColor = $GitPromptSettings.DefaultForegroundColor
	
# 	Write-VcsStatus
	
# 	$global:LASTEXITCODE = $realLASTEXITCODE
# 	Write-Host
# 	Write-Host -noNewline "[env:"
# 	if(_IsProduction) {
# 		Write-Host -noNewLine -foregroundColor Yellow $env
# 	} else {
# 		Write-Host -noNewLine -foregroundColor Magenta $env
# 	}
# 	return "]> "
# }
# Export-ModuleMember -Function Write-NuGetOpsPrompt