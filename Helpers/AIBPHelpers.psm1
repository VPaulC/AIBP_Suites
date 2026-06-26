# Module: Helpers for AI Readiness automation
# Exposes logging, retry, module/install helpers and small utilities

function New-RunId { return [guid]::NewGuid().ToString() }

function Write-Log {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('Info','Warning','Error','Verbose','Debug')][string]$Level = 'Info',
        [switch]$NoConsole
    )
    try {
        $timestamp = (Get-Date).ToString('o')
        $entry = [ordered]@{
            timestamp = $timestamp
            level     = $Level
            message   = $Message
            runId     = $script:RUN_ID
        }
        $json = $entry | ConvertTo-Json -Compress

        if (-not $NoConsole) {
            switch ($Level) {
                'Info'    { Write-Host "[$timestamp] [INFO] $Message" -ForegroundColor Green }
                'Warning' { Write-Warning "[$timestamp] [WARN] $Message" }
                'Error'   { Write-Host "[$timestamp] [ERROR] $Message" -ForegroundColor Red }
                'Verbose' { Write-Verbose $Message }
                'Debug'   { Write-Debug $Message }
            }
        }

        if ($script:LOG_DIR) {
            $logFile = Join-Path $script:LOG_DIR 'execution.jsonl'
            Add-Content -Path $logFile -Value $json
        }
    } catch {
        Write-Host "Failed to write log: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

function Initialize-PSGallery {
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { }
    if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
        Write-Log 'Installing NuGet package provider...' -Level Info
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
    }
    $psg = Get-PSRepository -Name 'PSGallery' -ErrorAction SilentlyContinue
    if ($psg -and $psg.InstallationPolicy -ne 'Trusted') {
        Write-Log 'PSGallery not trusted. Recommend setting to Trusted for automation.' -Level Warning
    }
}

function Ensure-Module {
    param(
        [Parameter(Mandatory)][string]$Name,
        [string]$MinimumVersion = ''
    )
    $installed = Get-Module -ListAvailable -Name $Name | Sort-Object Version -Descending | Select-Object -First 1
    if (-not $installed -or ($MinimumVersion -and ([version]$installed.Version -lt [version]$MinimumVersion))) {
        Write-Log "Installing module: $Name" -Level Info
        if ($MinimumVersion) {
            Install-Module -Name $Name -MinimumVersion $MinimumVersion -Scope CurrentUser -Force -AllowClobber
        } else {
            Install-Module -Name $Name -Scope CurrentUser -Force -AllowClobber
        }
    }
    Import-Module $Name -ErrorAction Stop
}

function Export-Json {
    param(
        [Parameter(Mandatory)]$Object,
        [Parameter(Mandatory)][string]$Path,
        [int]$Depth = 8
    )
    try {
        $Object | ConvertTo-Json -Depth $Depth | Out-File -FilePath $Path -Encoding utf8
        Write-Log "Exported to: $Path" -Level Info
    } catch {
        Write-Log "Failed to export JSON to $Path : $($_.Exception.Message)" -Level Warning
    }
}

function Invoke-RetryableOperation {
    param(
        [Parameter(Mandatory)][scriptblock]$ScriptBlock,
        [string]$OperationName = 'Operation',
        [int]$MaxRetries = 5,
        [int]$BaseDelayMs = 500
    )

    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        try {
            Write-Log "Attempting: $OperationName (attempt $attempt/$MaxRetries)" -Level Debug
            return & $ScriptBlock
        } catch {
            $err = $_.Exception
            $status = $null
            try { $status = $err.Response.StatusCode.Value__ } catch { }

            # Honor Retry-After header if present
            $retryAfter = $null
            try { $retryAfter = [int]($err.Response.Headers['Retry-After'][0]) } catch { }

            if ($attempt -lt $MaxRetries) {
                if ($retryAfter -and $retryAfter -gt 0) {
                    $wait = $retryAfter * 1000
                } else {
                    $wait = [math]::Pow(2, $attempt) * $BaseDelayMs
                }
                Write-Log "Operation failed (status=$status). Waiting $($wait)ms before retrying..." -Level Warning
                Start-Sleep -Milliseconds $wait
            } else {
                Write-Log "Operation failed after $MaxRetries attempts: $($err.Message)" -Level Error
                throw
            }
        }
    }
}

function Invoke-Graph {
    param(
        [Parameter(Mandatory)][ValidateSet('GET','POST','PATCH','DELETE','PUT')][string]$Method,
        [Parameter(Mandatory)][string]$Uri,
        [object]$Body = $null,
        [string]$Description = 'Graph request'
    )
    Invoke-RetryableOperation -ScriptBlock {
        if ($Body) {
            $json = $Body | ConvertTo-Json -Depth 25
            return Invoke-MgGraphRequest -Method $Method -Uri $Uri -Body $json -ContentType 'application/json'
        } else {
            return Invoke-MgGraphRequest -Method $Method -Uri $Uri
        }
    } -OperationName $Description
}

function Escape-FilterString {
    param([Parameter(Mandatory)][string]$String)
    return $String.Replace("'","''")
}

function Read-YesNo {
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [bool]$DefaultYes = $true
    )
    $defaultText = if ($DefaultYes) { '[Y]/N' } else { 'Y/[N]' }
    while ($true) {
        $r = Read-Host "$Prompt $defaultText"
        if ([string]::IsNullOrWhiteSpace($r)) { return $DefaultYes }
        switch ($r.Trim().ToLower()) {
            'y' { return $true }
            'yes' { return $true }
            'n' { return $false }
            'no' { return $false }
            default { Write-Host 'Please enter Y or N.' }
        }
    }
}

Export-ModuleMember -Function Write-Log,Initialize-PSGallery,Ensure-Module,Export-Json,Invoke-RetryableOperation,Invoke-Graph,Escape-FilterString,Read-YesNo,New-RunId
