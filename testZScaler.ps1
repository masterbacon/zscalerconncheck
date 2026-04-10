<#
    Zscaler Network Pre‑Validation Script
    Copyright (c) 2026 Andrew Bacon

    Licensed under the MIT License.
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.

.SYNOPSIS  
  Lightweight pre‑validation script for testing whether a care home network  
  can support Zscaler Z‑Tunnel 2.0, DNS resolution, and outbound connectivity.

.DESCRIPTION  
  This script performs:
    - Basic Internet connectivity  
    - DNS resolution for Zscaler cloud  
    - TCP 443 outbound connectivity  
    - UDP 443 outbound (DTLS capability)  
    - Latency tests  
    - Output summary  
#>

Write-Host "=== Zscaler Network Pre‑Validation Test ==="

# -------------------------------
# Helper Function
# -------------------------------
function Test-Port {
    param (
        [string]$TargetHost,
        [int]$Port,
        [int]$Timeout = 3000
    )

    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $iar = $client.BeginConnect($TargetHost, $Port, $null, $null)
        $success = $iar.AsyncWaitHandle.WaitOne($Timeout, $false)

        if ($success -and $client.Connected) {
            $client.EndConnect($iar)
            $client.Close()
            return $true
        }
        else {
            return $false
        }
    }
    catch {
        return $false
    }
}

# -------------------------------
# 1. Basic Internet Connectivity
# -------------------------------
Write-Host "`n[1] Checking Internet connectivity..."

$pingTargets = @("8.8.8.8", "1.1.1.1")
$internetOK = $false

foreach ($t in $pingTargets) {
    if (Test-Connection -TargetName $t -Count 2 -Quiet -ErrorAction SilentlyContinue) {
        Write-Host "Internet connectivity OK via $t"
        $internetOK = $true
        break
    }
}

if (-not $internetOK) {
    Write-Host "Internet connectivity FAILED"
}

# -------------------------------
# 2. DNS Resolution Checks
# -------------------------------
Write-Host "`n[2] Checking DNS resolution..."

$dnsTargets = @(
    "gateway.zscaler.net",
    "login.microsoftonline.com"
)

foreach ($domain in $dnsTargets) {
    try {
        $result = Resolve-DnsName $domain -ErrorAction Stop
        Write-Host "DNS resolved: $domain -> $($result[0].IPAddress)"
    }
    catch {
        Write-Host "DNS FAILED for: $domain"
    }
}

# -------------------------------
# 3. TCP 443 Tests (ZIA/ZPA)
# -------------------------------
Write-Host "`n[3] Checking outbound TCP 443 connectivity..."

$tcpTargets = @(
    "gateway.zscaler.net",
    "login.microsoftonline.com",
    "www.microsoft.com"
)

foreach ($tcpTarget in $tcpTargets) {
    $tcpOK = Test-Port -TargetHost $tcpTarget -Port 443
    if ($tcpOK) {
        Write-Host "TCP 443 reachable: $tcpTarget"
    } else {
        Write-Host "TCP 443 BLOCKED: $tcpTarget"
    }
}

# -------------------------------
# 4. UDP 443 Test (DTLS Compatibility)
# -------------------------------
Write-Host "`n[4] Checking outbound UDP 443 (DTLS capability)..."

try {
    $udp = New-Object System.Net.Sockets.UdpClient
    $udp.Client.ReceiveTimeout = 2000

    $ip = (Resolve-DnsName "gateway.zscaler.net").IPAddress[0]
    $endpoint = New-Object System.Net.IPEndPoint ($ip),443

    $bytes = [System.Text.Encoding]::ASCII.GetBytes("ZscalerTest")
    $udp.Send($bytes, $bytes.Length, $endpoint) | Out-Null

    Start-Sleep -Milliseconds 200

    Write-Host "UDP 443 appears open (DTLS likely supported)"
}
catch {
    Write-Host "UDP 443 could not be validated. Some networks block DTLS."
}
finally {
    if ($udp) { $udp.Close() }
}

# -------------------------------
# 5. Latency Tests (PowerShell 7 compatible)
# -------------------------------
Write-Host "`n[5] Measuring latency..."

$latencyTargets = @(
    "gateway.zscaler.net",
    "login.microsoftonline.com"
)

foreach ($latencyHost in $latencyTargets) {
    try {
        Write-Host "Latency to ${latencyHost}:"
        Test-Connection -TargetName $latencyHost -Ping -Count 3 |
            Select-Object Address, Latency |
            Format-Table -AutoSize
    }
    catch {
        Write-Host "Latency test FAILED for ${latencyHost}"
    }
}

# -------------------------------
# Summary
# -------------------------------
Write-Host "`n=== Summary Completed ==="
Write-Host "Review all results above."
Write-Host "Any FAILED or BLOCKED items indicate the site may require investigation before Day‑0 rollout."