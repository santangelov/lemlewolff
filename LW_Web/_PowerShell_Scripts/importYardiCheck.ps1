# Set strict error handling
$ErrorActionPreference = "Stop"

# API endpoint
$uri = "http://portal.lemlewolff.net/Import/ImportLatestEmailAttachments"

# Headers
$headers = @{
    "Content-Type" = "application/json"
}

# Log file path
$logFile = "F:\inetpub\wwwroot\lemlewolff.net\_Logs\YardiImportLog.txt"

# Start log entry
"--- API call started at $(Get-Date) ---" | Out-File $logFile -Append

try {
    # Send POST request
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers

    # Check for success flag
    if ($response.success -eq $true) {
        "SUCCESS: $($response.message) at $(Get-Date)" | Out-File $logFile -Append
    } else {
        "FAILURE: success=false - Message: $($response.message) at $(Get-Date)" | Out-File $logFile -Append
    }
}
catch {
    # If there's an exception or network issue
    "EXCEPTION: $_ at $(Get-Date)" | Out-File $logFile -Append
}
