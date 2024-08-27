# Created by Trent Menard
$host.UI.RawUI.WindowTitle = 'GlutInstaller'
Clear-Host

$baseDirectoryPathVS = "$Env:ProgramFiles\Microsoft Visual Studio"
$directoryPathSystem = "$Env:SystemDrive\Windows\System"
$directoryPathSystem32 = "$Env:SystemDrive\Windows\System32"

function Wait-ForExit {
    param (
		[CmdletBinding()]
        [string]$Message = "Press any key to continue..."
    )

    Write-Host $Message -ForegroundColor Yellow
    $null = $host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown") # Wait for a key press
}

function Test-PathOverride {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[string]$Path
	)

	if (!(Test-Path -Path $Path -PathType Container)) {
		Write-Host -ForegroundColor Red "[Fatal]: '$Path' doesn't exist. Can't continue."
		Exit -1
	}
}

function Get-VSVersion() {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[string]$Path
	)

	Test-PathOverride -Path $Path

	$version = Get-ChildItem -Name -Path $Path

	if (!($version)) {
		Write-Host -ForegroundColor Red "[Fatal]: '$Path' is empty (no version installed). Can't continue."
		Exit -1
	}

	# This would likely occur for major VS releases. I.e.: 2022 -> 2023 & when prev. isn't uninstalled.
	if ($version.Count -gt 1) {
		do {
			Write-Host -ForegroundColor Yellow "[Warning]: Found multiple versions of Visual Studio:"

			$version | ForEach-Object {
				Write-Host -ForegroundColor Yellow "  - $_"
			}

			Write-Host ""
			$versionInput = Read-Host -Prompt "Please specify the version number (e.g.: 2022)"

			if ($version -contains $versionInput) {
				return $versionInput
			}
			else {
				Write-Host -ForegroundColor Red "Invalid version. Please try again.`n"
			}

		} until ($version -contains $versionInput)

		return $versionInput
	}

	return $version
}

function Get-VSEdition() {
	param (
		[Parameter(Mandatory)]
		[string]$Path
	)

	Test-PathOverride -Path $Path

	$edition = Get-ChildItem -Name -Path $Path

	if (!($edition)) {
		Write-Host -ForegroundColor Red "[Fatal]: '$Path' is empty (no edition installed). Can't continue."
		Exit -1
	}

	# This is highly unlikely, but possible.
	if ($edition.Count -gt 1) {
		do {
			Write-Host -ForegroundColor Yellow "[Warning]: Found multiple Visual Studio editions:"

			$edition | ForEach-Object {
				Write-Host -ForegroundColor Yellow "  - $_"
			}

			Write-Host ""
			$editionInput = Read-Host -Prompt "Please specify the edition (e.g.: Community)"

			$caseSensitiveMatch = $edition | Where-Object { $_ -ceq $editionInput }

			if ($caseSensitiveMatch) {
				return $caseSensitiveMatch
			}

			else {
				Write-Host -ForegroundColor Red "Invalid edition. Please try again.`n"
			}

		} until ($caseSensitiveMatch)
	}

	return $edition
}

$vsVersion = Get-VSVersion -Path $baseDirectoryPathVS
Write-Host "Found Visual Studio Version: $vsVersion"

$directoryPathVS = Join-Path -Path $baseDirectoryPathVS -ChildPath $vsVersion

$vsEdition = Get-VSEdition -Path $directoryPathVS
Write-Host "Found Visual Studio Edition: $vsEdition"

$directoryPathVS = Join-Path -Path $directoryPathVS -ChildPath $vsEdition
$directoryPathMSVC = Join-Path -Path $directoryPathVS -ChildPath "VC\Tools\MSVC"

$msvcVersion = Get-VSVersion -Path $directoryPathMSVC
Write-Host "Found MSVC Version: $msvcVersion`n"

$directoryPathMSVC = Join-Path -Path $directoryPathMSVC -ChildPath $msvcVersion
$directoryPathMSVCLib = Join-Path -Path $directoryPathMSVC -ChildPath "lib"
$directoryPathMSVCIncludeGL = Join-Path $directoryPathMSVC -ChildPath "include\gl"

$glutH = Join-Path $PSScriptRoot -ChildPath "\glut-3.7.6\glut.h"
$glut32Lib = Join-Path $PSScriptRoot -ChildPath "\glut-3.7.6\glut32.lib"
$glut32DLL = Join-Path $PSScriptRoot -ChildPath "\glut-3.7.6\glut32.dll"

$copyToPathTargets = @(
	"$directoryPathMSVCLib\onecore\x64",
	"$directoryPathMSVCLib\onecore\x86",
	"$directoryPathMSVCLib\x64",
	"$directoryPathMSVCLib\x86"
)

$copyToPathTargets | ForEach-Object {
	Test-PathOverride -Path $_
	Write-Host "Copying ""glut32.lib"" to ""$_"""
	Copy-Item -Path "$glut32Lib" -Destination "$_" -Force
}

if (!(Test-Path "$directoryPathMSVCIncludeGL" -PathType Container)) {
	Write-Host "`nCreating ""$directoryPathMSVCIncludeGL"""
	New-Item -Path $directoryPathMSVCIncludeGL -Name "gl" -ItemType "directory"
}

Write-Host "Copying ""glut.h"" to ""$directoryPathMSVCIncludeGL"""
Copy-Item -Path "$glutH" -Destination "$directoryPathMSVCIncludeGL" -Force

$copyToPathTargets2 = @(
	"$directoryPathSystem",
	"$directoryPathSystem32"
)

$copyToPathTargets2 | ForEach-Object {
	Write-Host "Copying ""glut32.dll"" to ""$_"""
	Copy-Item -Path "$glut32DLL" -Destination "$_" -Force
}

Write-Host -ForegroundColor Green "`nDone! Remember to copy 'graph1.h' & 'graphLib2019' to future projects!`n"
Write-Host "Have fun, $Env:USERNAME!`n"
Wait-ForExit -Message "Press any key to exit.`n"