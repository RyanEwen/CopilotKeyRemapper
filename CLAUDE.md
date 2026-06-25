# Copilot Key Remapper — Claude Code Instructions

## Project overview

Copilot Key Remapper remaps the Windows 11 Copilot key via the **official Microsoft Copilot
hardware-key provider** model. It must ship as a signed **MSIX** to be assignable in
Settings. Reuses LittleLauncher patterns (WinUI 3 settings window, `SettingsManager`/
`UserSettings`, MSIX build script, and a tiny standalone handler exe like
LittleLauncher's Native-AOT companion).

## Architecture — TWO processes (keep this split)

The keypress path must stay thin and non-resident.

- **`CopilotKeyRemapperKey.exe`** (project `CopilotKeyRemapperKey/`) — the key handler. Self-contained,
  ReadyToRun, trimmed, single-file (flip `<PublishAot>` if VC++ build tools exist).
  Windows launches it on the key; `Program.cs` detects the gesture, reads
  `settings.json`, calls `ActionExecutor.RunSync`, and exits. No window, nothing resident.
  Shares model/catalog/executor with the settings app via **linked source files**
  (`<Compile Include="..\CopilotKeyRemapper\...">`), so those files must stay WinUI-free and
  AOT/trim-safe (no NLog, no reflection-heavy code).
- **`CopilotKeyRemapper.exe`** (project `CopilotKeyRemapper/`) — WinUI 3 settings UI only. Launched
  on demand; `SettingsWindow` is the main window; not resident; not in the keypress path.

Both ship in one MSIX (`CopilotKeyRemapperMSIX/`). Manifest has two `<Application>`s:
`Id="App"` = the handler (provider + protocol extension, `AppListEntry="none"`) —
**named "App" so the user's key assignment AUMID (`PFN!App`) survives updates**;
`Id="Settings"` = the WinUI app (visible Start tile).

## How the key maps

- Windows launches the handler (`Id="App"`) on a key press; it runs the single
  configured `Action`. Holding the key auto-repeats the launch, so the handler
  debounces (one press = one run) via a `repeat-state` timestamp + a named mutex.
- A press-and-hold protocol activation (`copilotkeyremapper-key://?state=Up`) is a
  no-op; the OS doesn't reliably deliver a distinct hold gesture, so hold was dropped.
- `ActionExecutor` runs the `Action` from settings.json: `SendInput` for key combos
  (it reuses a physically-held Win when triggered via Win+C), `Process.Start(UseShellExecute)`
  for app/URI/`ms-settings:`, and `explorer.exe` for `shell:AppsFolder\{AUMID}` apps.

## Shared types (WinUI-free, in `CopilotKeyRemapper/` but linked into the handler)

| File | Role |
|---|---|
| `Models/KeyCombo.cs` | Modifiers + VK; display string. |
| `Models/CopilotActionData.cs` | Plain POCO action (Type, Combo, LaunchPath, WindowsFunctionId). |
| `Models/WindowsFunction.cs` | Catalog entry. |
| `Services/WindowsFunctionCatalog.cs` | Curated grouped catalog. |
| `Services/ActionExecutor.cs` | `RunSync` (handler) / `Run` (UI test button); self-contained SendInput. |

WinUI-only: `Services/ActionSummary.cs`, `Services/CopilotKeyProvider.cs`
(assignment-status reader; `HandlerAppId = "App"`), `ViewModels/UserSettings.cs`,
`Classes/NativeMethods.cs` (settings-window P/Invoke only), pages, `SettingsWindow`.

## Conventions / gotchas

- Settings at `%AppData%\CopilotKeyRemapper\settings.json` (auto-redirected to package data
  when packaged — both exes resolve the same path).
- Linked shared files must be AOT/trim-safe — **no NLog** there (handler errors go to
  `ActionExecutor.ErrorSink` in the UI, or the handler's own `key-handler.log`).
- `global::` does not parse inside interpolated strings — assign to a local first.
- Fully-qualify `Microsoft.UI.Xaml.Visibility`/`FocusState` in page code-behind.
- **PowerShell build scripts must be ASCII** (Windows PowerShell 5.1 reads BOM-less
  `.ps1` as ANSI; a UTF-8 em-dash inside a string becomes a curly quote and breaks parsing).
- MSIX blocks reinstalling the same version with different content — bump
  `<Version>` in `Directory.Build.props` per build.

## Building

- Dev UI: `dotnet build CopilotKeyRemapper/CopilotKeyRemapper.csproj -c Debug`.
- Handler: `dotnet publish CopilotKeyRemapperKey/CopilotKeyRemapperKey.csproj -c Release -r win-arm64`.
- MSIX: `CopilotKeyRemapperMSIX/generate-msix-images.ps1` then `build-msix.ps1` (publishes both
  exes; finds SDK tools in an installed SDK or the `Microsoft.Windows.SDK.BuildTools`
  NuGet package). `-NoSign` for Store. Set `<Identity>` from Partner Center first.

## Adding a Windows function

Add an entry to `Services/WindowsFunctionCatalog.All` (unique `Id`, `Name`, `Group`,
`Description`, and a `Combo` or `ShellTarget`). It appears in the picker and is usable
by the handler automatically (the file is linked into both projects).
