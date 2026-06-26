# Copilot Assessment Script - Testing Guide

## Pre-Flight Checks

Before running the main assessment, verify prerequisites:

```powershell
# Check PowerShell version (requires 7.0+)
$PSVersionTable.PSVersion

# Expected output: 7.x.x or higher
# If not 7.0+, install from https://github.com/PowerShell/PowerShell/releases
```

---

## Test 1: Syntax Validation (No execution required)

**Goal**: Verify the script has no syntax errors

```powershell
# Download the script
cd ~/Downloads
$scriptPath = ".\Copilot assessment"

# Test syntax
$errors = @()
$null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $scriptPath), [ref]$errors)

if ($errors.Count -eq 0) {
  Write-Host "✅ Syntax valid - no parsing errors" -ForegroundColor Green
} else {
  Write-Host "❌ Syntax errors found:" -ForegroundColor Red
  $errors | Format-Table
}
```

**Expected Output**:
```
✅ Syntax valid - no parsing errors
```

---

## Test 2: Parameter Validation (10 seconds)

**Goal**: Verify parameter handling and help text

```powershell
# View all parameters
Get-Help ".\Copilot assessment" -Full

# Test parameter validation (should fail gracefully)
.\Copilot assessment -ConnectionTimeoutSeconds 5  # Too low (min: 10)
# Expected: Parameter validation error

.\Copilot assessment -ConnectionTimeoutSeconds 1000  # Too high (max: 600)
# Expected: Parameter validation error

.\Copilot assessment -LogLevel "Invalid"
# Expected: ValidateSet error
```

**Expected Output**:
```
Cannot bind argument to parameter 'ConnectionTimeoutSeconds' because it does not fall within the valid range of '10' to '600'.
```

---

## Test 3: Path Validation (5-10 seconds)

**Goal**: Verify early path checking and error handling

### Test 3a: Valid output path

```powershell
# Test with valid, writable path
$testPath = "$env:TEMP\CopilotTest_$(Get-Random)"
mkdir $testPath -Force | Out-Null

.\Copilot assessment `
  -OutputPath $testPath `
  -LogLevel "Info" `
  -SkipExchange `
  -SkipSharePoint

# Expected: Script proceeds to module bootstrap
```

**Expected Output**:
```
Initializing Copilot Readiness Assessment (v1.3)
SnapshotId: <GUID>
[CYAN] Output path is writable: C:\Users\...\CopilotTest_12345
[CYAN] SKU map not found; will use default SKU mappings
```

### Test 3b: Invalid output path (permission denied)

```powershell
# Test with invalid path (Windows system directory - no write access)
.\Copilot assessment `
  -OutputPath "C:\Windows\System32\TestOutput" `
  -LogLevel "Info"

# Expected: Immediate failure with helpful error message
```

**Expected Output**:
```
❌ Output path validation failed for 'C:\Windows\System32\TestOutput': Access is denied
Assessment Failed - Check logs for details
```

### Test 3c: Auto-create missing directory

```powershell
# Test with non-existent path (should auto-create)
$newPath = "$env:TEMP\CopilotAssessment_New_$(Get-Random)"

.\Copilot assessment `
  -OutputPath $newPath `
  -LogLevel "Info" `
  -SkipExchange `
  -SkipSharePoint

# Expected: Directory created, assessment proceeds
# Verify: Directory exists after script completes
ls $newPath
```

**Expected Output**:
```
Created output directory: C:\Users\...\CopilotAssessment_New_12345
Output path is writable: C:\Users\...\CopilotAssessment_New_12345
```

---

## Test 4: Module Bootstrap (30-60 seconds)

**Goal**: Verify automatic module installation and import

```powershell
# Test with modules already installed (fast path)
.\Copilot assessment `
  -OutputPath "$env:TEMP\CopilotTest" `
  -LogLevel "Info" `
  -AutoInstallMissingModules $true `
  -SkipExchange `
  -SkipSharePoint

# Expected: Modules imported quickly (already installed)
# Duration: 10-20 seconds
```

**Expected Output**:
```
Step 1/14: Bootstrap-PackageManagement [████░░░░░░] 7%
Step 2/14: Bootstrap-Modules [████████░░] 14%
```

### Uninstall a module to test auto-install

```powershell
# Uninstall a module to force fresh install (takes 20-40 seconds)
Uninstall-Module 'Microsoft.Graph.Authentication' -Force -ErrorAction SilentlyContinue

# Now run script - should reinstall
.\Copilot assessment `
  -OutputPath "$env:TEMP\CopilotTest" `
  -LogLevel "Info" `
  -AutoInstallMissingModules $true `
  -SkipExchange `
  -SkipSharePoint

# Expected: Script installs missing module, then proceeds
```

---

## Test 5: Connection Timeout Enforcement (5-10 seconds)

**Goal**: Verify timeout protection on Graph and Exchange connections

### Test 5a: Normal connection (60s timeout)

```powershell
# This will prompt for authentication - use your Microsoft account
.\Copilot assessment `
  -OutputPath "$env:TEMP\CopilotTest" `
  -LogLevel "Info" `
  -ConnectionTimeoutSeconds 60 `
  -SkipExchange `
  -SkipSharePoint

# Expected: Connection succeeds within 60 seconds
# Log: "Connected to Microsoft Graph successfully"
```

**Expected Output**:
```
Step 3/14: Connect-MicrosoftGraph [████░░░░░░] 21%
Connecting to Microsoft Graph with 60s timeout...
Connected to Microsoft Graph successfully
```

### Test 5b: Unrealistic timeout (will fail)

```powershell
# Test with 10-second timeout (probably too short for interactive auth)
.\Copilot assessment `
  -OutputPath "$env:TEMP\CopilotTest" `
  -LogLevel "Info" `
  -ConnectionTimeoutSeconds 10 `
  -SkipExchange \
  -SkipSharePoint

# Expected: Either succeeds (if auth is cached) or times out after 10s
```

**Expected Output** (if timeout):
```
Connecting to Microsoft Graph with 10s timeout...
❌ Graph connection timeout after 10 seconds
Assessment Failed - Check logs for details
```

---

## Test 6: SKU Caching Verification (30-60 seconds)

**Goal**: Verify SKU cache is populated and reused

```powershell
# Run with debug logging to see cache hits
.\Copilot assessment `
  -OutputPath "$env:TEMP\CopilotTest" `
  -LogLevel "Debug" `
  -SkipExchange `
  -SkipSharePoint `
  -Verbose

# Expected: See cache messages like:
# - "Fetching fresh subscription SKU data from Graph"
# - "Cached X SKUs"
# - "Returning cached SKUs (age: Xs)"
```

**Expected Output** (in log file):
```
[DEBUG] [SkuCache] Fetching fresh subscription SKU data from Graph
[DEBUG] [SkuCache] Cached 12 SKUs
[DEBUG] [SkuCache] Returning cached SKUs (age: 2s)
[DEBUG] [SkuCache] Returning cached SKUs (age: 5s)
```

---

## Test 7: Progress Indicators (Full run ~2-3 minutes)

**Goal**: Verify progress bar shows real-time step progress

```powershell
# Run full assessment with progress visible
.\Copilot assessment `
  -OutputPath "$env:TEMP\CopilotFullTest" `
  -LogLevel "Info" `
  -ConnectionTimeoutSeconds 120 `
  -GraphCommandTimeoutSeconds 120

# Watch for progress bar advancing through steps
# Expected: 14 steps, each with progress percentage
```

**Expected Output** (in console):
```
Step 3/14: Connect-MicrosoftGraph [████░░░░░░░░] 21%
Step 4/14: Fetch-SubscribedSkus [██████░░░░░░░] 28%
Step 5/14: Fetch-TenantInfo [████████░░░░░░] 35%
Step 6/14: Fetch-Users-Licensing [██████████░░░░] 42%
...
Step 14/14: Export-Run-Summary [██████████████] 100%

Assessment Complete!
```

---

## Test 8: CSV Output Validation (Immediate)

**Goal**: Verify CSV files are created with correct structure

```powershell
# Check if CSVs were created
$outputDir = "$env:TEMP\CopilotFullTest"
Get-ChildItem "$outputDir\*.csv" | Format-Table Name, Length

# Expected output:
# Name                                     Length
# ----                                     ------
# Users_Licensing.csv                      12345
# Entra_ConditionalAccess.csv              5678
# Entra_Roles.csv                          2345
# Teams_Groups.csv                         3456
# Summary_Scores.csv                       456
# Run_Summary.csv                          1234
# Run_Errors.csv                           0 (empty if no errors)
# Run_Warnings.csv                         0 (empty if no warnings)
```

### Inspect CSV contents

```powershell
# View header row
Import-Csv "$outputDir\Users_Licensing.csv" -First 1 | Format-Table

# View summary scores
Import-Csv "$outputDir\Summary_Scores.csv" | Format-Table

# Count entries
(Import-Csv "$outputDir\Users_Licensing.csv").Count
```

**Expected Output**:
```
UserId UserPrincipalName DisplayName AccountEnabled HasCopilotAddOn HasEligibleBaseSku
------ ------------------ ----------- -------------- --------------- ------------------
<GUID> user@contoso.com   John Doe    True           False           True
```

---

## Test 9: Error Handling & Cleanup (Full run + cleanup)

**Goal**: Verify errors are captured and cleanup occurs

### Test 9a: Intentional error (missing Graph connection)

```powershell
# Create a mock to force failure
$outputDir = "$env:TEMP\CopilotErrorTest"

# This will fail at Graph connection step
.\Copilot assessment `
  -OutputPath $outputDir `
  -LogLevel "Info" `
  -ConnectionTimeoutSeconds 1 `
  -SkipExchange `
  -SkipSharePoint

# Expected: Fails after attempting Graph connection, generates error reports
```

**Expected Output**:
```
Assessment Failed - Check logs for details
```

### Check error logs

```powershell
# View errors that were captured
$errorFile = "$outputDir\Run_Errors.csv"
if (Test-Path $errorFile) {
  Import-Csv $errorFile | Format-Table Step, Message | Select-Object -First 5
}

# View full error details in log file
$logFile = Get-ChildItem "$outputDir\logs\*.log" | Select-Object -First 1
tail -50 $logFile.FullName
```

**Expected Output**:
```
Step                                 Message
----                                 -------
Connect-MicrosoftGraph               Failed after 3 attempts
Graph connection timeout after 1 seconds
```

### Verify cleanup occurred

```powershell
# Check that cache was cleared (log entry should show this)
tail -20 $logFile.FullName | Select-String "SKU cache cleared"

# Expected: "SKU cache cleared" appears in error cleanup section
```

---

## Test 10: Retry Logic Verification (60-90 seconds)

**Goal**: Verify operations retry on transient failures

```powershell
# Enable verbose logging to see retry attempts
.\Copilot assessment `
  -OutputPath "$env:TEMP\CopilotRetryTest" `
  -LogLevel "Debug" `
  -RetryCount 3 `
  -RetryDelaySeconds 2 `
  -SkipExchange \
  -SkipSharePoint \
  -Verbose

# Expected: If any step fails, log will show "Starting attempt X of 3"
```

**Expected Output** (if transient failure occurs):
```
[INFO] [Fetch-Users-Licensing] Starting attempt 1 of 3
[WARN] [Fetch-Users-Licensing] Attempt 1 failed: Throttled
[INFO] [Fetch-Users-Licensing] Retrying in 2 seconds
[INFO] [Fetch-Users-Licensing] Starting attempt 2 of 3
[INFO] [Fetch-Users-Licensing] Succeeded on attempt 2
```

---

## Test 11: Optional Features (Various)

### Test 11a: MFA Methods collection

```powershell
.\Copilot assessment `
  -OutputPath "$env:TEMP\CopilotMfaTest" `
  -LogLevel "Info" `
  -IncludeMfaMethods \
  -SkipExchange \
  -SkipSharePoint

# Expected: Entra_MFA_Methods.csv should be created
```

### Test 11b: Purview features

```powershell
.\Copilot assessment `
  -OutputPath "$env:TEMP\CopilotPurviewTest" `
  -LogLevel "Info" `
  -IncludePurview \
  -IncludeDataClassification \
  -SkipExchange \
  -SkipSharePoint

# Expected: Purview_*.csv files should be created
```

---

## Test 12: Full Assessment Run (3-5 minutes)

**Goal**: Complete end-to-end workflow test with all features

```powershell
# Full assessment with all options enabled
$testDir = "$env:TEMP\CopilotFullAssessment_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

.\Copilot assessment `
  -OutputPath $testDir `
  -LogLevel "Info" `
  -ConnectionTimeoutSeconds 120 `
  -GraphCommandTimeoutSeconds 120 `
  -IncludeMfaMethods `
  -IncludePurview `
  -IncludeDataClassification `
  -RetryCount 3 `
  -RetryDelaySeconds 2

# Monitor progress and verify final output
```

**Expected Output**:
```
Initializing Copilot Readiness Assessment (v1.3)
SnapshotId: <GUID>
Step 1/14: Bootstrap-PackageManagement [████░░░░░░░░░░] 7%
Step 2/14: Bootstrap-Modules [████████░░░░░░░░] 14%
...
Assessment Complete!
Output path: C:\Users\...\CopilotFullAssessment_20260626_052219
Total steps executed: 14 / 14
Errors: 0, Warnings: 0
```

### Verify all outputs

```powershell
# List all generated files
Get-ChildItem $testDir -Recurse | Where-Object { $_.Extension -eq '.csv' -or $_.Extension -eq '.log' }

# Expected: 8-10 CSV files + 1 log file

# View summary scores
Import-Csv "$testDir\Summary_Scores.csv"

# Expected: Licensing score and Copilot assignment summary
```

---

## Performance Benchmarks

Compare your results against these baselines (100-user tenant):

| Metric | Expected | Your Result |
|--------|----------|-------------|
| Baseline run time | 90-120s | _______ |
| Full run time | 180-240s | _______ |
| Graph API calls | ~8 | _______ |
| SKU cache hits | 3+ | _______ |
| Module bootstrap | 10-20s | _______ |
| Authentication | 5-15s | _______ |

---

## Troubleshooting

### Connection Timeout

```powershell
# If "Graph connection timeout after 60 seconds"
# → Increase timeout:
.\Copilot assessment `
  -ConnectionTimeoutSeconds 180 `
  -GraphCommandTimeoutSeconds 180

# → Or check network:
Test-NetConnection -ComputerName graph.microsoft.com -Port 443
```

### Module Installation Fails

```powershell
# Manually install problematic module:
Install-Module -Name Microsoft.Graph.Authentication -Scope CurrentUser -Force

# Then retry script
```

### Permission Denied on CSV Write

```powershell
# Use a different output directory:
.\Copilot assessment -OutputPath "$env:TEMP\CopilotTest"
```

### Throttling Errors

```powershell
# Increase retry delay:
.\Copilot assessment `
  -RetryCount 5 `
  -RetryDelaySeconds 5
```

---

## Cleanup

```powershell
# Remove test directories
Remove-Item "$env:TEMP\CopilotTest*" -Recurse -Force -ErrorAction SilentlyContinue

# Clear PowerShell job queue
Get-Job | Remove-Job -Force -ErrorAction SilentlyContinue

# Disconnect Graph (if still connected)
Disconnect-MgGraph -ErrorAction SilentlyContinue
```

---

## Success Checklist

- [ ] Syntax validation passes
- [ ] Parameter validation works (rejects invalid values)
- [ ] Path validation catches invalid/read-only directories
- [ ] Directories auto-created when needed
- [ ] Bootstrap completes without errors
- [ ] Graph connection succeeds with timeout protection
- [ ] SKUs cached and reused (fewer API calls)
- [ ] Progress bar shows all 14 steps
- [ ] All CSV files generated with correct structure
- [ ] Error handling captures and logs issues
- [ ] Cleanup removes cache and disconnects services
- [ ] Retry logic works on transient failures
- [ ] Optional features (MFA, Purview) work when enabled
- [ ] Full run completes successfully
- [ ] Performance matches or exceeds benchmarks

---

## Next Steps

1. ✅ Complete all tests above
2. 📊 Compare performance against benchmarks
3. 🔧 Document any issues or customizations needed
4. 📈 Monitor production runs for patterns/failures
5. 🎯 Adjust parameters based on your tenant characteristics

