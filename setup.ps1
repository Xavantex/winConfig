<#
.SYNOPSIS
Install core tools

.DESCRIPTION
Inspired by config files and reinstallation.
#>

# Need to make sure you have winget first
# Check if windows 10

Begin
{

	$win10 = (gin).OsName -match 10
	
	function winstall
	{
		param($tool)
		if (winget list --id $tool -e --source winget | sls -Pattern "No installed package found")
		{
			winget install --id $tool -e --source winget --accept-source-agreements --accept-package-agreements
		}
	}
	
	function ctwinstall
	{
		param($tool, $dlURL)
		if (winget list $tool | sls -Pattern "No installed package found")
		{
			iwr $dlURL -OutFile "$tool.exe"
			.\$tool.exe
			erase $tool.exe
		}
	}
	
	function forcewinstall
	{
		param($tool)
		winget install --id $tool -e --source winget --accept-source-agreements --accept-package-agreements
	}
}

Process
{

	# Download winget if we do not have it
	if (!(gcm winget -errorAction SilentlyContinue))
	{
		# get latest download url
		$URL = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
		$URL = (iwr $URL -UseBasicParsing).Content | ConvertFrom-Json |
				select -ExpandProperty "assets" |
				where "browser_download_url" -Match '.msixbundle' |
				select -ExpandProperty "browser_download_url"

		# download
		iwr $URL -OutFile "Setup.msix" -UseBasicParsing

		# install
		Add-AppxPackage -Path "Setup.msix"

		# delete file
		erase "Setup.msix"
	}


	# Check that Powershell is above version 5 and if not install.
	# Should add check if pwrshell 7 already is installed, not just this environment.
	#if ($PSVersionTable.PSVersion.Major -ge 7)
	#{
	#	winget install --id Microsoft.Powershell -e --source winget --accept-source-agreements --accept-package-agreements
	#}
	if ($PSVersionTable.PSVersion -lt [Version]"7.0")
	{
		winget install --id Microsoft.PowerShell -e --source winget --accept-source-agreements --accept-package-agreements
		$PSScriptRoot\scripts\Update-Environment.ps1
		saps -Verb RunAs pwsh -File $MyInvocation.MyCommand.Definition
		exit
	}


	# Remove sticky keys, toggle keys, filter keys
	sp -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Value "506" -Force
	sp -Path "HKCU:\Control Panel\Accessibility\ToggleKeys" -Name "Flags" -Value "58" -Force
	sp -Path "HKCU:\Control Panel\Accessibility\Keyboard Response" -Name "Flags" -Value "122" -Force

	# Set Keyboard delay to low, and keyboard speed to high
	sp 'HKCU:\Control Panel\Keyboard' -Name 'KeyboardDelay' -Value '0' -Force
	sp 'HKCU:\Control Panel\Keyboard' -Name 'KeyboardSpeed' -Value '31' -Force


	# Install GIT
	winstall Git.Git
	# Won't recognize that git is installed otherwise
	$PSScriptRoot\scripts\Update-Environment.ps1

	# Install 7-zip
	winstall 7zip.7zip


	#Install LunarVim

	# Install Neovim first
	# Neovim not above 9.0 on winget, get nightly
	winstall Neovim.Neovim.Nightly


	# Install latest and "greatest" stable python
	#winstall Python.Python
	if (python --version 2>&1 | sls -Pattern "Python was not found")
	{
		forcewinstall Python.Python.3.9
	}
	#}

	# Install Make
	winstall GnuWin32.Make
	# Adding to path, this will NOT remove any symlink and dynamic items, such as %systemroot% or %NVM_HOME%
	[Environment]::SetEnvironmentVariable("Path",
	(gi -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" ).
	GetValue('Path', '', 'DoNotExpandEnvironmentNames') + ";C:\Program Files (x86)\GnuWin32\bin",
	[EnvironmentVariableTarget]::Machine)

	# Install Rustup, recommended Rust installation
	# Check what flags to use for most automation
	winstall Rustlang.Rustup

	# NVM node.js + npm version manager
	winstall CoreyButler.NVMforWindows
	# Install latest lts at 64 bit
	nvm install lts 64
	# Use latest lts at 64 bit
	nvm use lts 64


	# Install Lunarvim config
	if (!(gcm lvim -errorAction SilentlyContinue))
	{
		pwsh -c "`$LV_BRANCH='release-1.3/neovim-0.9'; iwr https://raw.githubusercontent.com/LunarVim/LunarVim/release-1.3/neovim-0.9/utils/installer/install.ps1 -UseBasicParsing | iex"
	}
	

	# Install steam
	winstall Valve.Steam

	# Install SteamCMD to install games
	# This expects steam is in C:
	# No real good way to see where steam is installed at the moment
	if (!(Test-Path -Path "C:\Program Files (x86)\Steam\steamcmd.exe" -PathType Leaf))
	{
		iwr "https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip" -OutFile "steamcmd.zip"
		Expand-Archive "steamcmd.zip" "C:\Program Files (x86)\Steam"
	#	setx /M path "%path%;C:\Program Files (x86)\SteamCMD\"
		erase "steamcmd.zip"
	# Install steam games deemed necessary
		$steamuser = Read-Host -Prompt "Please enter username to steam"
		& 'C:\Program Files (x86)\Steam\steamcmd' +login $steamuser +runscript $PSScriptRoot\scripts\steamInstalls.txt
	}
	
	pwsh -c "& `'C:\Program Files (x86)\Steam\steam.exe`'"
	
	# Install step CLI for certificates
	winstall Smallstep.step
	
	# Install discord for friends
	# Look at updating toward spacebarchat
	winstall Discord.Discord
	
	# <3 VLC for media
	winstall VideoLAN.VLC
	
	# Install firefox
	winstall Mozilla.Firefox
	
	# Install thunderbird
	# There is betterbird, a supposedly patched thunderbird : Betterbird.Betterbird
	winstall Mozilla.Thunderbird
	
	# Install sound blaster
	winstall CreativeTechnology.SoundBlasterCommand
	
	# Install wootility
	ctwinstall wootility-lekker "https://api.wooting.io/public/wootility/download?os=win&branch=lekker"
	
	# Dell display manager for my displays
	winstall Dell.DisplayManager
	
	# Install latest iCUE, check if winstall have latest
	ctwinstall iCUE "https://downloads.corsair.com/Files/icue/Install-iCUE.exe"
	
	# Install jellyfin 
	winstall Jellyfin.JellyfinMediaPlayer
	
	# Install Windows Terminal
	winstall Microsoft.WindowsTerminal
	
	# Only download, no reliable way to know if installed already
	iwr "https://www.microsoft.com/en-us/download/confirmation.aspx?id=102134" -OutFile "$PSScriptRoot\winKeyLayout\MSKLC.exe"

	Read-Host -Prompt "Scripts Completed : Press any key to exit"
}