# Need to make sure you have winget first
# Check if windows 10

$win10 = (Get-ComputerInfo).OsName -match 10

# Download winget if we do not have it
if (!(Get-Command winget -errorAction SilentlyContinue))
{
	# get latest download url
	$URL = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
	$URL = (Invoke-WebRequest -Uri $URL).Content | ConvertFrom-Json |
			Select-Object -ExpandProperty "assets" |
			Where-Object "browser_download_url" -Match '.msixbundle' |
			Select-Object -ExpandProperty "browser_download_url"

	# download
	Invoke-WebRequest -Uri $URL -OutFile "Setup.msix" -UseBasicParsing

	# install
	Add-AppxPackage -Path "Setup.msix"

	# delete file
	Remove-Item "Setup.msix"
}

# Install GIT
if (!(Get-Command git -errorAction SilentlyContinue))
{
	winget install --id Git.Git -e --source winget --accept-source-agreements --accept-package-agreements
}


# Check that Powershell is above version 5 and if not install.
# Should add check if pwrshell 7 already is installed, not just this environment.
if ($PSVersionTable.PSVersion.Major -ge 7)
{
	winget install --id Microsoft.Powershell -e --source winget --accept-source-agreements --accept-package-agreements
}


#Install LunarVim


# Install Neovim first
if (!(Get-Command neovim -errorAction SilentlyContinue))
{
	#Add version checking if neovim exists
	
	# get latest download url
	$URL = "https://api.github.com/repos/neovim/neovim/releases/latest"
	$URL = (Invoke-WebRequest -Uri $URL).Content | ConvertFrom-Json |
			Select-Object -ExpandProperty "assets" |
			Where-Object "browser_download_url" -Match '.msixbundle' |
			Where-Object "browser_download_url" -NotMatch ".sha256sum" |
			Select-Object -ExpandProperty "browser_download_url"

	# download
	Invoke-WebRequest -Uri $URL -OutFile "Setup.msi" -UseBasicParsing

	# install
	Start-Process msiexec.exe -ArgumentList "/i `"Setup.msi`" /quiet /passive" -Wait -Path 

	# delete file
	Remove-Item "Setup.msix"
}

# Install latest and "greatest" stable python
#if (!(Get-Command python -errorAction SilentlyContinue))
#{
if (Python --version | -match "Python was not found")
{
	winget install --id Python.Python --source winget --accept-source-agreements --accept-package-agreements
}
#}

if (!(Get-Command neovim -errorAction SilentlyContinue))
{
	winget install -e --id GnuWin32.Make --source winget --accept-source-agreements --accept-package-agreements
}

if (!(Get-Command cargo -errorAction SilentlyContinue))
{
	
	Invoke-WebRequest -Uri "https://static.rust-lang.org/rustup/dist/i686-pc-windows-gnu/rustup-init.exe" -OutFile "rust-up.exe" -UseBasicParsing
	rust-up.exe
	Remove-Item "rust-up.exe"
}

if (!(Get-Command npm -errorAction SilentlyContinue))
{
	winget install -e --id CoreyButler.NVMforWindows --source winget --accept-source-agreements --accept-package-agreements
}

if (!(Get-Command lvim -errorAction SilentlyContinue))
{
	pwsh -c "`$LV_BRANCH='release-1.3/neovim-0.9'; iwr https://raw.githubusercontent.com/LunarVim/LunarVim/release-1.3/neovim-0.9/utils/installer/install.ps1 -UseBasicParsing | iex"
}