# Zscaler Network Pre‑Validation Script

This repository contains a lightweight PowerShell script used to validate whether a remote site or care home network is suitable for running Zscaler ZIA/ZPA services.  
It is designed for environments where corporate-managed laptops may be deployed into locations with unknown or unmanaged network conditions.

The script performs the following checks:

1. **Internet Connectivity**
   - Tests basic reachability of public internet DNS resolvers.

2. **DNS Resolution**
   - Confirms that key Zscaler and Microsoft cloud endpoints resolve correctly.

3. **Outbound TCP 443 Tests**
   - Checks whether secure HTTPS traffic can reach Zscaler and Microsoft service endpoints.
   - Required for Zscaler Z-Tunnel 2.0 (TLS fallback) and all cloud apps.

4. **Outbound UDP 443 Tests**
   - Attempts a DTLS‑friendly outbound UDP handshake.
   - Recommended for Zscaler Z‑Tunnel 2.0 performance (not strictly required).

5. **Latency Measurements**
   - Measures round‑trip latency to Zscaler service edges and Microsoft login endpoints.

## Purpose

The script is intended for **pre‑deployment network verification**, especially before sending corporate devices into newly acquired sites or remote offices where:

- Wi‑Fi quality is uncertain
- ISP quality varies
- Firewall or DNS restrictions may interfere with Zscaler operation

It enables a site’s local IT (or any capable staff member) to run a simple, non‑intrusive validation and report any issues before rollout.

## Requirements

- Windows device (PowerShell 5.1 or PowerShell 7.x)
- Ability to run unsigned scripts (or place the script in an authorised execution policy scope)
- No administrative rights required
- No Zscaler software needed on the device

## Usage

```powershell
# From PowerShell, run:
.\testZscaler.ps1
