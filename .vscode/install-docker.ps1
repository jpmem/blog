function Confirm-VisualStudioCodeShutdown {
	Write-Host -NoNewline 'Shut down Visual Studio Code now? [Y/n] (defaults to Y in 5 seconds): '
	$deadline = [DateTime]::UtcNow.AddSeconds(5)

	while ([DateTime]::UtcNow -lt $deadline) {
		if ([Console]::KeyAvailable) {
			$key = [Console]::ReadKey($true).Key
			if ($key -eq [ConsoleKey]::Y) {
				Write-Host 'Y'
				return $true
			}
			if ($key -eq [ConsoleKey]::N) {
				Write-Host 'n'
				return $false
			}
		}

		Start-Sleep -Milliseconds 100
	}
	Write-Host 'timeout'
	return $true
}

function Test-DockerEngine {
	& docker info *> $null
	return $LASTEXITCODE -eq 0
}

function Start-DockerEngine {
	if (Test-DockerEngine) {
		Write-Host 'Docker Engine is already running.'
		return
	}

	$dockerDesktopPath = Join-Path $env:ProgramFiles 'Docker\Docker\Docker Desktop.exe'
	if (-not (Test-Path $dockerDesktopPath)) {
		throw "Docker Desktop was not found at '$dockerDesktopPath'."
	}

	Write-Host 'Starting Docker Desktop...'
	Start-Process $dockerDesktopPath
	$deadline = [DateTime]::UtcNow.AddMinutes(5)
	do {
		Start-Sleep -Seconds 2
		if (Test-DockerEngine) {
			Write-Host 'Docker Engine is ready.'
			return
		}
	} while ([DateTime]::UtcNow -lt $deadline)

	throw 'Docker Engine did not become ready within 5 minutes.'
}

if (Get-Command docker -ErrorAction SilentlyContinue) {
	Write-Host 'Docker is already installed.'
	Start-DockerEngine
	exit 0
}
Write-Host 'Docker not installed.'

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
	Write-Host 'WinGet was not found.'
	throw 'WinGet is required to install Docker Desktop.'
}

Write-Host 'Installing Docker Desktop...'
winget install --id Docker.DockerDesktop --exact --accept-package-agreements --accept-source-agreements
if ($LASTEXITCODE -ne 0) {
	Write-Host "Docker Desktop installation failed with exit code $LASTEXITCODE."
	exit $LASTEXITCODE
}

Write-Host 'Docker Desktop was installed successfully.'
if (-not (Confirm-VisualStudioCodeShutdown)) {
	Write-Host '*** Please restart Visual Studio Code before running the debug task again. ***' -ForegroundColor Red
	exit 1
}

Write-Host 'Shutting down Visual Studio Code to refresh PATH on the next launch...'
Get-Process -Name Code -ErrorAction SilentlyContinue | Stop-Process -Force