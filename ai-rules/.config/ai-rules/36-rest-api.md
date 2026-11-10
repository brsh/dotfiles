---
trigger: model_decision
description: "REST API scripting patterns — activate when writing scripts that call HTTP APIs using Invoke-RestMethod, Python requests, or C# HttpClient"
---

# REST API Scripting Patterns

These rules apply when writing scripts or tools that consume REST APIs.
Patterns are provided for PowerShell (`Invoke-RestMethod`), Python (`requests`),
and C# (`HttpClient`). Consistent habits across all three: authenticate properly,
handle errors explicitly, handle pagination, and never log credentials.

---

## Authentication Patterns

### Bearer Token (OAuth2 / Azure AD / Microsoft Graph)

**PowerShell:**
```powershell
# Get a token using client credentials (service principal)
function Get-AccessToken {
    param(
        [string]$TenantId,
        [string]$ClientId,
        [string]$ClientSecret,
        [string]$Scope = "https://graph.microsoft.com/.default"
    )
    $body = @{
        grant_type    = 'client_credentials'
        client_id     = $ClientId
        client_secret = $ClientSecret
        scope         = $Scope
    }
    $response = Invoke-RestMethod -Method Post `
        -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" `
        -Body $body -ContentType 'application/x-www-form-urlencoded'
    return $response.access_token
}

$token = Get-AccessToken -TenantId $env:TENANT_ID `
    -ClientId $env:CLIENT_ID -ClientSecret $env:CLIENT_SECRET

$headers = @{ Authorization = "Bearer $token" }

Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users" `
    -Headers $headers -Method Get
```

**Python:**
```python
import requests
import os

def get_access_token(tenant_id: str, client_id: str, client_secret: str,
                     scope: str = "https://graph.microsoft.com/.default") -> str:
    url = f"https://login.microsoftonline.com/{tenant_id}/oauth2/v2.0/token"
    data = {
        "grant_type": "client_credentials",
        "client_id": client_id,
        "client_secret": client_secret,
        "scope": scope,
    }
    resp = requests.post(url, data=data)
    resp.raise_for_status()
    return resp.json()["access_token"]

token = get_access_token(
    os.environ["TENANT_ID"],
    os.environ["CLIENT_ID"],
    os.environ["CLIENT_SECRET"],
)
session = requests.Session()
session.headers["Authorization"] = f"Bearer {token}"
```

**C#:**
```csharp
// Use Azure.Identity for Azure AD tokens — handles refresh automatically
using Azure.Identity;
using Azure.Core;

var credential = new ClientSecretCredential(
    tenantId: Environment.GetEnvironmentVariable("TENANT_ID"),
    clientId: Environment.GetEnvironmentVariable("CLIENT_ID"),
    clientSecret: Environment.GetEnvironmentVariable("CLIENT_SECRET")
);

var tokenRequest = new TokenRequestContext(["https://graph.microsoft.com/.default"]);
var token = await credential.GetTokenAsync(tokenRequest, cancellationToken);

httpClient.DefaultRequestHeaders.Authorization =
    new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token.Token);
```

### API Key Authentication

**PowerShell:**
```powershell
$headers = @{
    'X-API-Key' = $env:API_KEY          # header name varies by API
    'Authorization' = "ApiKey $env:API_KEY"  # some APIs use this form
}
```

**Python:**
```python
session.headers["X-API-Key"] = os.environ["API_KEY"]
```

### Basic Authentication

**PowerShell:**
```powershell
$cred = [Convert]::ToBase64String(
    [Text.Encoding]::ASCII.GetBytes("$($env:API_USER):$($env:API_PASS)")
)
$headers = @{ Authorization = "Basic $cred" }

# Or use -Credential parameter (PS 6+)
$credential = [PSCredential]::new($env:API_USER,
    (ConvertTo-SecureString $env:API_PASS -AsPlainText -Force))
Invoke-RestMethod -Uri $uri -Credential $credential -AllowUnencryptedAuthentication:$false
```

**Python:**
```python
session.auth = (os.environ["API_USER"], os.environ["API_PASS"])
```

---

## Making Requests and Handling Errors

### PowerShell

```powershell
function Invoke-ApiRequest {
    param(
        [string]$Uri,
        [hashtable]$Headers,
        [string]$Method = 'Get',
        [hashtable]$Body
    )

    $params = @{
        Uri     = $Uri
        Headers = $Headers
        Method  = $Method
    }
    if ($Body) {
        $params.Body = $Body | ConvertTo-Json -Depth 10
        $params.ContentType = 'application/json'
    }

    try {
        Invoke-RestMethod @params -ErrorAction Stop
    } catch [System.Net.Http.HttpRequestException] {
        Write-Error "Network error calling $Uri : $_"
        throw
    } catch {
        # PS 7+ — StatusCode is on $_.Exception.Response
        $statusCode = $_.Exception.Response?.StatusCode
        $body = $_.ErrorDetails?.Message
        Write-Error "HTTP $statusCode from $Uri : $body"
        throw
    }
}
```

```powershell
# PS 7+ — cleaner error handling with -StatusCodeVariable
$response = Invoke-WebRequest -Uri $uri -Headers $headers -SkipHttpErrorCheck
if ($response.StatusCode -ge 400) {
    Write-Error "HTTP $($response.StatusCode): $($response.Content)"
}
$data = $response.Content | ConvertFrom-Json
```

### Python

```python
import requests
from requests.exceptions import HTTPError, Timeout, ConnectionError

def api_get(session: requests.Session, url: str, **kwargs) -> dict:
    try:
        response = session.get(url, timeout=30, **kwargs)
        response.raise_for_status()   # raises HTTPError for 4xx/5xx
        return response.json()
    except HTTPError as e:
        logger.error("HTTP %s from %s: %s",
                     e.response.status_code, url, e.response.text[:500])
        raise
    except Timeout:
        logger.error("Timeout calling %s", url)
        raise
    except ConnectionError:
        logger.error("Connection failed to %s", url)
        raise
```

### C#

```csharp
public async Task<T> GetAsync<T>(string url, CancellationToken ct = default)
{
    var response = await _httpClient.GetAsync(url, ct);

    if (!response.IsSuccessStatusCode)
    {
        var body = await response.Content.ReadAsStringAsync(ct);
        throw new HttpRequestException(
            $"HTTP {(int)response.StatusCode} from {url}: {body[..Math.Min(500, body.Length)]}",
            inner: null,
            statusCode: response.StatusCode);
    }

    return await response.Content.ReadFromJsonAsync<T>(cancellationToken: ct)
        ?? throw new InvalidOperationException("Null response body");
}
```

---

## Pagination

Most APIs return results in pages. Always handle pagination — never assume one call
returns all data.

### Link Header Pagination (GitHub API, etc.)

**PowerShell:**
```powershell
function Get-AllPages {
    param([string]$StartUri, [hashtable]$Headers)

    $uri = $StartUri
    do {
        $response = Invoke-WebRequest -Uri $uri -Headers $Headers
        $data = $response.Content | ConvertFrom-Json
        $data.value ?? $data   # Graph uses .value; others return array directly

        # Parse Link header for next page
        $linkHeader = $response.Headers['Link']
        $uri = if ($linkHeader -match '<([^>]+)>;\s*rel="next"') { $Matches[1] } else { $null }
    } while ($uri)
}
```

**Python:**
```python
def get_all_pages(session: requests.Session, url: str) -> list:
    results = []
    while url:
        response = session.get(url, timeout=30)
        response.raise_for_status()
        data = response.json()

        # Handle both { "value": [...] } and bare list responses
        page_items = data.get("value", data) if isinstance(data, dict) else data
        results.extend(page_items)

        # Link header pagination
        next_link = response.links.get("next", {}).get("url")
        # Or @odata.nextLink (Microsoft Graph)
        url = data.get("@odata.nextLink") or next_link
    return results
```

### Microsoft Graph Specific (odata.nextLink)

**PowerShell:**
```powershell
function Get-GraphAllPages {
    param([string]$Uri, [hashtable]$Headers)

    $results = [System.Collections.Generic.List[object]]::new()
    do {
        $response = Invoke-RestMethod -Uri $Uri -Headers $Headers
        $results.AddRange($response.value)
        $Uri = $response.'@odata.nextLink'
    } while ($Uri)

    return $results
}

# Usage
$allUsers = Get-GraphAllPages `
    -Uri "https://graph.microsoft.com/v1.0/users?`$select=displayName,userPrincipalName,accountEnabled&`$top=999" `
    -Headers $headers
```

---

## Rate Limiting and Retry

APIs return `429 Too Many Requests` when you exceed their rate limits.
Always handle this with exponential backoff.

### PowerShell

```powershell
function Invoke-WithRetry {
    param(
        [scriptblock]$ScriptBlock,
        [int]$MaxRetries = 5,
        [int]$BaseDelaySeconds = 2
    )

    $attempt = 0
    do {
        try {
            return & $ScriptBlock
        } catch {
            $statusCode = $_.Exception.Response?.StatusCode?.value__
            $isRetryable = $statusCode -in @(429, 500, 502, 503, 504)

            if (-not $isRetryable -or $attempt -ge $MaxRetries) { throw }

            # Respect Retry-After header if present
            $retryAfter = $_.Exception.Response?.Headers?.'Retry-After'
            $delay = if ($retryAfter) { [int]$retryAfter } `
                     else { $BaseDelaySeconds * [math]::Pow(2, $attempt) }

            Write-Warning "HTTP $statusCode — retrying in ${delay}s (attempt $($attempt+1)/$MaxRetries)"
            Start-Sleep -Seconds $delay
            $attempt++
        }
    } while ($true)
}

# Usage
$result = Invoke-WithRetry { Invoke-RestMethod -Uri $uri -Headers $headers }
```

### Python

```python
# Use the requests-retry adapter from urllib3
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

def build_session() -> requests.Session:
    session = requests.Session()
    retry = Retry(
        total=5,
        backoff_factor=2,           # waits 2, 4, 8, 16, 32 seconds between retries
        status_forcelist=[429, 500, 502, 503, 504],
        respect_retry_after_header=True,   # honor Retry-After header
    )
    adapter = HTTPAdapter(max_retries=retry)
    session.mount("https://", adapter)
    session.mount("http://", adapter)
    return session
```

### C#

```csharp
// Use Polly (install: dotnet add package Polly.Extensions.Http)
using Polly;
using Polly.Extensions.Http;

var retryPolicy = HttpPolicyExtensions
    .HandleTransientHttpError()           // 5xx and network errors
    .OrResult(r => r.StatusCode == System.Net.HttpStatusCode.TooManyRequests)
    .WaitAndRetryAsync(
        retryCount: 5,
        sleepDurationProvider: (attempt, outcome, _) =>
        {
            // Honor Retry-After if present
            if (outcome.Result?.Headers.RetryAfter?.Delta is { } delta)
                return delta;
            return TimeSpan.FromSeconds(Math.Pow(2, attempt));
        });

// Register with IHttpClientFactory in DI
services.AddHttpClient<MyApiClient>()
        .AddPolicyHandler(retryPolicy);
```

---

## Common APIs — Quick Reference

### Microsoft Graph

```powershell
# Base URL: https://graph.microsoft.com/v1.0/
# Auth: OAuth2 Bearer token (Azure AD)
# Docs: https://learn.microsoft.com/en-us/graph/api/overview

# Prefer the Microsoft.Graph PowerShell module for routine tasks
Connect-MgGraph -Scopes "User.Read.All"
Get-MgUser -Filter "accountEnabled eq false" -All

# Use Invoke-MgGraphRequest for endpoints not yet in the module
Invoke-MgGraphRequest -Method GET `
    -Uri "https://graph.microsoft.com/v1.0/users?`$filter=accountEnabled eq false&`$top=999"
```

### Azure Resource Manager REST API

```powershell
# Use Az module for most operations — only use REST directly for unsupported features
# Base URL: https://management.azure.com/
# Auth: Bearer token with scope https://management.azure.com/.default

$token = (Get-AzAccessToken -ResourceUrl "https://management.azure.com/").Token
$headers = @{ Authorization = "Bearer $token" }

Invoke-RestMethod `
    -Uri "https://management.azure.com/subscriptions/$subId/resourceGroups?api-version=2021-04-01" `
    -Headers $headers
```

### GitHub API

```powershell
# Base URL: https://api.github.com/
# Auth: Bearer token (Personal Access Token or GitHub App token)
$headers = @{
    Authorization = "Bearer $env:GITHUB_TOKEN"
    Accept        = "application/vnd.github+json"
    'X-GitHub-Api-Version' = '2022-11-28'
}

Invoke-RestMethod -Uri "https://api.github.com/repos/owner/repo/issues" `
    -Headers $headers
```

---

## Security Rules

- **Never log the full request/response** if it might contain auth tokens, passwords,
  or sensitive data. Log the URL and status code only.
- **Always use HTTPS** — never `http://` for APIs that handle credentials or sensitive data.
- **Store tokens in environment variables**, not in code, config files, or git history.
- **Check token expiry** — tokens have lifetimes. Cache and refresh rather than
  re-authenticating on every request.
- **Validate TLS certificates** — never set `SkipCertificateCheck` / `verify=False` /
  `ServerCertificateCustomValidationCallback` to always-true in production. These
  disable protection against MITM attacks.
- **Scope tokens minimally** — request only the permissions your script needs
  (e.g., `User.Read.All` not `Directory.ReadWrite.All` if you're only reading users).

---

## Common Pitfalls to Flag

- `Invoke-RestMethod` without `-ErrorAction Stop` in try/catch → won't catch HTTP errors
- `verify=False` in Python requests → disables TLS validation; flag always
- No pagination handling → script silently returns partial data for large datasets
- No retry logic for `429` → intermittent failures on rate-limited APIs
- Logging `$headers` or the response when it contains tokens → credential leak
- `ConvertTo-Json` without `-Depth` on nested objects → nested objects become `@{...}` strings (default depth is 2)
- Token reuse without checking expiry → failures after token lifetime expires
- Hardcoded tenant IDs or subscription IDs → use environment variables or config files
- Not setting `Content-Type: application/json` when sending a JSON body → API may reject or misparse the request
