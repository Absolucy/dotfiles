Function Test-CommandExists {
	Param ($command)
	$oldPreference = $ErrorActionPreference
	$ErrorActionPreference = 'stop'
	try {
		if (Get-Command $command) {
			RETURN $true
		}
	} Catch {
		RETURN $false
	} Finally {
		$ErrorActionPreference=$oldPreference
	}
}

If (Test-CommandExists starship) {
	Invoke-Expression (&starship init powershell)
}

If (Test-CommandExists zoxide) {
	Invoke-Expression (& {
		$hook = if ($PSVersionTable.PSVersion.Major -lt 6) { 'prompt' } else { 'pwd' }
		(zoxide init --hook $hook powershell | Out-String)
	})
}

If (Test-CommandExists Set-PsFzfOption && Test-CommandExists Set-PSReadLineKeyHandler) {
	Set-PsFzfOption -TabExpansion -PSReadlineChordReverseHistory 'UpArrow'
	Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }
}

If (Test-CommandExists fnm) {
	fnm env --use-on-cd | Out-String | Invoke-Expression
}

If (Test-CommandExists eza) {
	Remove-Item -Path Alias:ls -Force -ErrorAction SilentlyContinue
	function ls_eza { eza --color=auto --icons=auto --hyperlink @args }
	Set-Alias -Name ls -Value ls_eza

	Remove-Item -Path Alias:ll -Force -ErrorAction SilentlyContinue
	function ll_eza { eza --color=auto --icons=auto --long --all --binary --hyperlink --header @args }
	Set-Alias -Name ll -Value ll_eza
}

function Load-Vs-Shell {
	[CmdletBinding()]
	param (
		[ValidateSet("x86", "x64", IgnoreCase = $true)]
		[Parameter()]
		$Arch = 'x64',

		[ValidateSet("x86", "x64", IgnoreCase = $true)]
		[Parameter()]
		$HostArch = 'x64',

		[ValidateSet("MSVC", "Clang", IgnoreCase = $true)]
		[Parameter()]
		$Compiler = 'MSVC',

		[Parameter(ValueFromRemainingArguments = $true)]
		$Arguments
	)

	# Find Visual Studio installation path
	$vs_path = &(Join-Path ${env:ProgramFiles(x86)} "\Microsoft Visual Studio\Installer\vswhere.exe") -property installationpath
	if (-not $vs_path) {
		throw "Visual Studio installation not found. Please install Visual Studio with C++ workload."
	}

	# Import the DevShell module
	Import-Module (Join-Path $vs_path "Common7\Tools\Microsoft.VisualStudio.DevShell.dll")

	# Prepare compiler configuration
	$vsDevShellParams = @{
		VsInstallPath = $vs_path
	}

	# Set up architecture configuration
	$archStr = switch ($Arch) {
		'x86' { 'x86' }
		'x64' { 'amd64' }
	}

	$hostArchStr = switch ($HostArch) {
		'x86' { 'x86' }
		'x64' { 'amd64' }
	}

	# Set architecture parameters
	$vsDevShellParams['Arch'] = $archStr
	$vsDevShellParams['HostArch'] = $hostArchStr

	# Add any additional arguments passed to the function
	if ($Arguments) {
		foreach ($arg in $Arguments) {
			if ($arg -match '^-(?<key>[^=]+)=(?<value>.+)$') {
				$vsDevShellParams[$matches['key']] = $matches['value']
			}
		}
	}

	# Enter Visual Studio Developer Shell
	Enter-VsDevShell @vsDevShellParams

	if ($Compiler -eq "MSVC") {
		Set-Item -Path "env:CC" -Value "cl.exe"
		Set-Item -Path "env:CXX" -Value "cl.exe"
	} elseif ($Compiler -eq "Clang") {
		Set-Item -Path "env:CC" -Value "clang-cl.exe"
		Set-Item -Path "env:CXX" -Value "clang-cl.exe"
	} else {
		throw "Compiler should be MSVC or Clang!"
	}

	# Output configuration info
	Write-Host "Visual Studio Developer Shell loaded with configuration:" -ForegroundColor Green
	Write-Host " → Target Architecture: $Arch" -ForegroundColor Cyan
	Write-Host " → Host Architecture: $HostArch" -ForegroundColor Cyan
	Write-Host " → Compiler: $Compiler" -ForegroundColor Cyan
}


function Find-ScoopExe {
	param(
		[Parameter(Mandatory=$true)]
		[string]$Package,

		[Parameter(Mandatory=$true)]
		[string]$Executable
	)

	$packagePath = scoop prefix $Package
	if ($LASTEXITCODE -ne 0) {
		Write-Error "Failed to get path for scoop package '$Package'"
		return $null
	}

	# Use fd to search recursively for the executable
	# --type x for executables only
	# -1 to stop after first match
	$result = fd -1 --type x "^$Executable$" $packagePath
	if ($LASTEXITCODE -ne 0) {
		Write-Error "Failed to find '$Executable' in '$packagePath'"
		return $null
	}

	return $result
}
