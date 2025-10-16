# ==========================================================
#  Windows Autopilot Hash → OneTimeSecret
#  Runs without authentication, ideal for OOBE use
# ==========================================================

# 1️⃣  Collect Autopilot hardware hash (base64)
try {
    Write-Host "Collecting hardware hash..."
    $hwData = Get-CimInstance -Namespace root\cimv2\mdm\dmmap -ClassName MDM_DevDetail_Ext01 -ErrorAction Stop
    $hardwareHash = $hwData.DeviceHardwareData
    $serialNumber = (Get-CimInstance Win32_BIOS).SerialNumber.Trim()
    $hostname     = $env:COMPUTERNAME
}
catch {
    Write-Warning "Unable to read Autopilot hash. Are you running on Windows 10/11 OOBE?"
    exit 1
}

# 2️⃣  Combine into a structured object for easier processing later
$payload = @{
    serialNumber  = $serialNumber
    deviceName    = $hostname
    hardwareHash  = $hardwareHash
} | ConvertTo-Json -Compress

# 3️⃣  Post to OneTimeSecret (no auth)
try {
    Write-Host "Uploading hash to OneTimeSecret..."
    $otsUrl = "https://us.onetimesecret.com/api/v2/secret/conceal"
    $body   = @{
        secret = @{
            secret = $payload
        }
    } | ConvertTo-Json -Compress

    $otsResp = Invoke-RestMethod -Uri $otsUrl -Method Post -Body $body -ContentType "application/json"
    $secretId = $otsResp.record.secret.key
    if (-not $secretId) { throw "Invalid response from OneTimeSecret." }

    
}
catch {
    Write-Warning "Failed to upload to OneTimeSecret: $($_.Exception.Message)"
    exit 1
}

# 4️⃣  Display the link
Write-Host ""
Write-Host "✅ One-time secret URL (give this to sysadmin):"
Write-Host "    $secretId"
Write-Host ""
Write-Host "⚠️  Remember: the OneTimeSecret link can only be opened once and expires in 60 minutes."
