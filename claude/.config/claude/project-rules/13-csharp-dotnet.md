---
trigger: glob
glob: "**/*.{cs,csproj,sln,cshtml,razor}"
description: "C# and .NET best practices — sysadmin tooling, scripting, and game development"
---

# C# / .NET Rules

These rules are calibrated for someone coming from a PowerShell/scripting background
who is learning C# for sysadmin tooling, automation, and eventually game development.
Explanations will bridge PowerShell concepts to C# equivalents where helpful.

---

## .NET Version Guidance

| Version | Type | Recommended For |
|---------|------|----------------|
| .NET 8 | LTS (supported until Nov 2026) | All new tools and production use |
| .NET 9 | STS (18-month support) | Experimentation, personal projects |
| .NET Framework 4.x | Legacy (Windows only) | Only when maintaining existing code |

**Default to .NET 8 LTS** for any new tool or project. Avoid .NET Framework for new
code — it is Windows-only and receives only security fixes.

---

## Project Setup (dotnet CLI)

```bash
# Create projects
dotnet new console -n MyTool -f net8.0         # console app
dotnet new classlib -n MyLib -f net8.0         # class library
dotnet new tool -n MyGlobalTool -f net8.0      # dotnet global tool (installable)
dotnet new xunit -n MyTool.Tests -f net8.0     # test project

# Solution management
dotnet new sln -n MySolution
dotnet sln add src/MyTool/MyTool.csproj
dotnet sln add tests/MyTool.Tests/MyTool.Tests.csproj

# NuGet packages
dotnet add package Spectre.Console              # rich terminal output
dotnet add package System.CommandLine          # modern CLI argument parsing
dotnet add package Microsoft.Extensions.Logging

# Build and run
dotnet build
dotnet run
dotnet run -- --arg1 value                     # pass args to the app

# Publish (self-contained single executable)
dotnet publish -c Release -r win-x64 --self-contained -p:PublishSingleFile=true
dotnet publish -c Release -r linux-x64 --self-contained -p:PublishSingleFile=true
```

---

## Project File (.csproj)

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net8.0</TargetFramework>
    <RootNamespace>MyTool</RootNamespace>
    <AssemblyName>mytool</AssemblyName>
    <Nullable>enable</Nullable>           <!-- enable nullable reference types -->
    <ImplicitUsings>enable</ImplicitUsings> <!-- auto-imports common namespaces -->
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
    <AllowUnsafeBlocks>false</AllowUnsafeBlocks>

    <!-- For publishing as a single executable -->
    <PublishSingleFile>true</PublishSingleFile>
    <SelfContained>true</SelfContained>
    <RuntimeIdentifier>win-x64</RuntimeIdentifier>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Spectre.Console" Version="0.49.*" />
    <PackageReference Include="System.CommandLine" Version="2.0.0-beta4.*" />
  </ItemGroup>
</Project>
```

**Enable `<Nullable>enable</Nullable>`** in all new projects. Nullable reference types
catch null reference bugs at compile time — one of the most impactful features in
modern C#. This is a learning priority.

---

## Language Fundamentals (PowerShell Bridge)

### Variables and Types

```csharp
// PowerShell: $name = "Brian"
// C#: explicitly typed — the compiler infers the type with 'var'
var name = "Brian";               // string (inferred)
string name = "Brian";            // same, explicit type
int count = 42;
bool isEnabled = true;

// PowerShell: $null
// C#: null — but with nullable enabled, you must declare intent
string? maybeNull = null;         // nullable string (? means "can be null")
string notNull = "guaranteed";    // cannot be null (compiler enforces)

// Constants (like Set-Variable -Option ReadOnly)
const int MaxRetries = 3;
const string DefaultServer = "server01.contoso.com";
```

### String Operations

```csharp
// Interpolation (like PS f-strings / "$variable")
string host = "server01";
int port = 8080;
string message = $"Connecting to {host}:{port}";

// Multi-line (like PS here-strings)
string query = """
    SELECT Name, LastLogon
    FROM AD_Users
    WHERE Enabled = 0
    """;

// String methods
"hello world".ToUpper()          // "HELLO WORLD"
"  trimmed  ".Trim()             // "trimmed"
"a,b,c".Split(',')               // string[] { "a", "b", "c" }
string.Join(", ", new[] {"a","b","c"})  // "a, b, c"
"path/to/file".Replace("/", "\\")
```

### Collections (like PS arrays and hashtables)

```csharp
// List (like PS ArrayList or List[T] — preferred over arrays for mutable collections)
var servers = new List<string> { "web01", "web02", "db01" };
servers.Add("db02");
servers.Remove("web01");
servers.Count;     // length

// Dictionary (like PS hashtable @{})
var config = new Dictionary<string, string>
{
    ["server"] = "db01.contoso.com",
    ["database"] = "MyApp",
    ["timeout"] = "30"
};
config["port"] = "1433";         // add or update
config.ContainsKey("server");    // true
config.TryGetValue("port", out var portValue);  // safe get

// Arrays — fixed size (use List<T> instead for most cases)
string[] names = { "Alice", "Bob" };
```

---

## Console App Structure (Sysadmin Tool Pattern)

```csharp
// Program.cs — top-level statements (C# 9+, no class/Main boilerplate needed)
using System.CommandLine;
using Microsoft.Extensions.Logging;

var serverOption = new Option<string>(
    name: "--server",
    description: "Target server hostname or IP") { IsRequired = true };

var verboseOption = new Option<bool>(
    name: "--verbose",
    description: "Enable verbose output");

var rootCommand = new RootCommand("Checks disk usage on remote servers")
{
    serverOption,
    verboseOption
};

rootCommand.SetHandler(async (server, verbose) =>
{
    using var loggerFactory = LoggerFactory.Create(builder =>
    {
        builder.AddConsole();
        if (verbose) builder.SetMinimumLevel(LogLevel.Debug);
    });

    var logger = loggerFactory.CreateLogger("DiskChecker");

    try
    {
        await CheckDiskAsync(server, logger);
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Failed to check disk on {Server}", server);
        Environment.Exit(1);
    }
}, serverOption, verboseOption);

return await rootCommand.InvokeAsync(args);
```

---

## Error Handling

```csharp
// try/catch/finally — same concept as PowerShell
try
{
    var result = await ConnectToServerAsync(hostname);
    await ProcessResultAsync(result);
}
catch (TimeoutException ex)
{
    logger.LogError("Connection to {Host} timed out: {Message}", hostname, ex.Message);
    throw;   // re-throw to let the caller handle it (like 'throw' in PS)
}
catch (UnauthorizedAccessException ex)
{
    logger.LogError("Access denied to {Host}: {Message}", hostname, ex.Message);
    Environment.Exit(1);   // exit with error code (like sys.exit(1) in Python)
}
catch (Exception ex)
{
    logger.LogError(ex, "Unexpected error processing {Host}", hostname);
    throw;
}
finally
{
    // Always runs — cleanup connections, temp files, etc.
    connection?.Dispose();
}
```

**Always use specific exception types** where possible. Catching `Exception` is
the catch-all — fine as a last resort, but prefer catching specific types first.

---

## Async / Await (important in .NET — not in PS 5.1)

C# is heavily async. Most I/O operations (network, file, HTTP) have async versions.
Prefer async throughout — mixing sync and async incorrectly causes deadlocks.

```csharp
// Pattern: async method returns Task or Task<T>
// (Task is like a Promise/Future — a value that will arrive later)
public async Task<List<string>> GetOnlineServersAsync(
    IEnumerable<string> servers,
    CancellationToken cancellationToken = default)
{
    var online = new List<string>();

    foreach (var server in servers)
    {
        try
        {
            using var ping = new System.Net.NetworkInformation.Ping();
            var reply = await ping.SendPingAsync(server, timeout: 2000);
            if (reply.Status == System.Net.NetworkInformation.IPStatus.Success)
                online.Add(server);
        }
        catch (Exception ex)
        {
            logger.LogDebug("Ping failed for {Server}: {Message}", server, ex.Message);
        }
    }

    return online;
}

// Parallel async (check many servers at once)
var tasks = servers.Select(s => CheckServerAsync(s, cancellationToken));
var results = await Task.WhenAll(tasks);
```

**Naming convention**: async methods are named with the `Async` suffix by convention.

---

## .NET as a PowerShell Enhancer

You already use .NET types in PowerShell. C# makes them first-class:

```csharp
// These are the same types you use in PowerShell via [TypeName]::Method()

// PS: [System.IO.Path]::Combine($a, $b)
// C#:
string fullPath = Path.Combine(baseDir, "logs", "output.log");

// PS: [System.Net.Dns]::GetHostEntry($hostname)
// C#:
var hostEntry = await Dns.GetHostEntryAsync(hostname);

// PS: [System.Collections.Generic.List[string]]::new()
// C#:
var list = new List<string>();

// PS: [regex]::Match($text, $pattern)
// C#:
var match = Regex.Match(text, @"\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}");
if (match.Success) { var ip = match.Value; }

// PS: [System.Text.Encoding]::UTF8.GetBytes($str)
// C#:
byte[] bytes = Encoding.UTF8.GetBytes(myString);
```

Learning C# deepens your understanding of what PowerShell is actually doing under the
hood — every `[TypeName]` you use in PS is a .NET type.

---

## Useful NuGet Packages for Sysadmin Tools

| Package | Purpose |
|---------|---------|
| `Spectre.Console` | Rich terminal output: tables, progress bars, prompts, colors |
| `System.CommandLine` | Modern CLI arg parsing (Microsoft, replaces older options) |
| `Microsoft.Extensions.Logging` | Structured logging with multiple providers |
| `Microsoft.Extensions.Configuration` | Config files, env vars, command-line config |
| `Polly` | Retry, circuit breaker, timeout policies for resilient HTTP calls |
| `SSH.NET` | SSH connections and SFTP from C# |
| `WinRM` / `Microsoft.Management.Infrastructure` | WinRM and CIM from C# |
| `Microsoft.Graph` | Microsoft Graph API (same as PS Microsoft.Graph module) |
| `Azure.Identity` | Azure authentication (managed identity, service principal, etc.) |
| `Azure.ResourceManager` | Azure resource management from C# |
| `Dapper` | Lightweight SQL query library (simpler than Entity Framework for scripts) |
| `YamlDotNet` | YAML parsing |
| `Newtonsoft.Json` / `System.Text.Json` | JSON (System.Text.Json is built-in to .NET) |

---

## Build Tooling (.NET CLI and MSBuild)

```bash
# Build configurations
dotnet build -c Debug       # debug build (default)
dotnet build -c Release     # optimized release build

# Publish targets
dotnet publish -c Release -r win-x64   --self-contained   # Windows EXE
dotnet publish -c Release -r linux-x64 --self-contained   # Linux binary
dotnet publish -c Release -r osx-arm64 --self-contained   # macOS Apple Silicon

# As a dotnet global tool (installable via 'dotnet tool install')
# In .csproj: <PackAsTool>true</PackAsTool>
dotnet pack
dotnet tool install --global --add-source ./nupkg MyTool

# Run tests
dotnet test
dotnet test --filter "Category=Integration"
dotnet test --collect:"XPlat Code Coverage"

# Analyze code
dotnet format                          # format code (like black for Python)
dotnet build -warnaserror              # fail on any warnings
```

### Global.json — Pin SDK Version

```json
{
  "sdk": {
    "version": "8.0.100",
    "rollForward": "latestMinor"
  }
}
```

Place `global.json` in the repo root to ensure all contributors use the same SDK version.

---

## Game Development in C#

### Unity (most popular, largest ecosystem)

```csharp
// Unity uses C# with its own runtime (Mono or IL2CPP)
// MonoBehaviour is the base class for game scripts attached to objects
using UnityEngine;

public class PlayerController : MonoBehaviour
{
    [SerializeField] private float moveSpeed = 5f;  // editable in Unity Inspector
    private Rigidbody _rb;

    private void Awake()
    {
        _rb = GetComponent<Rigidbody>();
    }

    private void FixedUpdate()
    {
        float h = Input.GetAxis("Horizontal");
        float v = Input.GetAxis("Vertical");
        _rb.MovePosition(transform.position +
            new Vector3(h, 0, v) * moveSpeed * Time.fixedDeltaTime);
    }
}
```

Unity-specific notes:
- Unity uses its own coroutine system (`IEnumerator` + `yield return`) alongside
  async/await — prefer async/await for new Unity 6+ code.
- `[SerializeField]` exposes private fields in the Unity Inspector.
- `Update()` runs every frame; `FixedUpdate()` runs at fixed physics timesteps.
- Unity's asset pipeline and scene system are separate from standard .NET — don't
  try to use Unity APIs outside the Unity editor/player context.
- **Learning path**: Unity Learn (`learn.unity.com`) is excellent and free.

### MonoGame (code-first, cross-platform)

```csharp
// MonoGame is closer to raw .NET — you control everything
// Good for 2D games and learning graphics fundamentals
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

public class MyGame : Game
{
    private GraphicsDeviceManager _graphics;
    private SpriteBatch _spriteBatch;
    private Texture2D _playerTexture;

    public MyGame()
    {
        _graphics = new GraphicsDeviceManager(this);
        Content.RootDirectory = "Content";
    }

    protected override void LoadContent()
    {
        _spriteBatch = new SpriteBatch(GraphicsDevice);
        _playerTexture = Content.Load<Texture2D>("player");
    }

    protected override void Draw(GameTime gameTime)
    {
        GraphicsDevice.Clear(Color.CornflowerBlue);
        _spriteBatch.Begin();
        _spriteBatch.Draw(_playerTexture, new Vector2(100, 100), Color.White);
        _spriteBatch.End();
        base.Draw(gameTime);
    }
}
```

### Godot with C# (GodotSharp)

```csharp
// Godot 4 supports C# as a first-class language alongside GDScript
using Godot;

public partial class Player : CharacterBody2D
{
    [Export] public float Speed = 200f;  // like Unity's [SerializeField]

    public override void _PhysicsProcess(double delta)
    {
        var velocity = Vector2.Zero;
        if (Input.IsActionPressed("ui_right")) velocity.X += 1;
        if (Input.IsActionPressed("ui_left"))  velocity.X -= 1;
        if (Input.IsActionPressed("ui_up"))    velocity.Y -= 1;
        if (Input.IsActionPressed("ui_down"))  velocity.Y += 1;

        Velocity = velocity.Normalized() * Speed;
        MoveAndSlide();
    }
}
```

Godot notes:
- `[Export]` makes properties editable in the Godot Inspector (like Unity's `[SerializeField]`).
- Godot uses signals (its own event system) — learn `EmitSignal` / `Connect`.
- C# in Godot requires the Mono-enabled build. Not all platforms support C# (iOS is limited).
- GDScript is lighter and better documented in Godot docs; C# is better for complex logic.

---

## Code Style

- **Naming**: `PascalCase` for classes, methods, properties, and public fields.
  `camelCase` for local variables and parameters. `_camelCase` (underscore prefix)
  for private fields.
- **Braces**: always on their own line (Allman style — standard in .NET ecosystem).
- **`var`**: use it when the type is obvious from the right-hand side. Use explicit
  types when clarity matters.
- **Nullable**: enable it and treat nullable warnings as seriously as errors.
- **File-scoped namespaces**: use them (C# 10+) — less indentation:
  ```csharp
  namespace MyTool.Utilities;   // file-scoped — applies to whole file
  
  public class Helper { ... }
  ```

---

## Common Pitfalls to Flag (especially coming from PowerShell/scripting)

- Mixing `async` and `.Result` / `.Wait()` → causes deadlocks; use `await` consistently
- Catching `Exception` without re-throwing → hides bugs; always rethrow or log+exit
- Not enabling `<Nullable>enable</Nullable>` → misses a whole class of null bugs
- `string` concatenation in loops → use `StringBuilder` or LINQ `string.Join()`
- `List<T>` vs `IEnumerable<T>` confusion → prefer `IEnumerable<T>` in method signatures
  for flexibility; use `List<T>` internally
- Not disposing resources (`HttpClient`, `SqlConnection`, streams) → use `using` statements
- `HttpClient` instantiated in a loop → create once (or use `IHttpClientFactory`);
  each instance holds socket connections
- `DateTime.Now` in comparisons → use `DateTime.UtcNow` for consistency across timezones
- String comparison with `==` on user input → use `string.Equals(a, b, StringComparison.OrdinalIgnoreCase)`
  for case-insensitive comparisons
