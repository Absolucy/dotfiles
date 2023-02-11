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
	Set-PsFzfOption -TabExpansion
	Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }
}
If (Test-CommandExists fnm) {
	fnm env --use-on-cd | Out-String | Invoke-Expression
}
