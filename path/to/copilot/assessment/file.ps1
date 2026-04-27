# PowerShell Copilot Assessment

## New-HtmlReport

This function generates an HTML report for the readiness data collected from Microsoft 365 services.

### Function Definition 
```powershell
function New-HtmlReport {
    param (
        [string]$ReportData,
        [string]$OutputPath = "C:\Reports\ReadyReport.html"
    )

    $htmlContent = @"
    <html>
    <head>
        <title>Readiness Report</title>
        <style>
            body { font-family: Arial, sans-serif; }
            table { border-collapse: collapse; width: 100%; }
            th, td { border: 1px solid #dddddd; text-align: left; padding: 8px; }
            th { background-color: #f2f2f2; }
        </style>
    </head>
    <body>
        <h1>Readiness Report</h1>
        <table>
            <tr>
                <th>Item</th>
                <th>Status</th>
            </tr>
            @{foreach ($item in $ReportData) {
                <tr>
                    <td>$item.Item</td>
                    <td>$item.Status</td>
                </tr>
            }}
        </table>
    </body>
    </html>
    "@ 
    
    # Save to file
    $htmlContent | Out-File -FilePath $OutputPath -Encoding UTF8
}
```

## Main Script Execution
```powershell
try {
    # Connect to Microsoft 365 services
    Connect-M365Service -Credential (Get-Credential)

    # Collect readiness data
    $readinessData = Get-ReadinessData

    # Generate the HTML report
    New-HtmlReport -ReportData $readinessData

    # Export results to CSV
    $csvPath = "C:\Reports\ReadinessData.csv"
    $readinessData | Export-Csv -Path $csvPath -NoTypeInformation
} catch {
    Write-Error "An error occurred: $_"
} finally {
    # Clean up resources if needed
    Disconnect-M365Service
}
```

The above script defines the `New-HtmlReport` function and includes the main script execution logic to connect, gather data, generate HTML reports, and export results. Ensure that the Microsoft 365 PowerShell module is installed and properly configured in your environment.
