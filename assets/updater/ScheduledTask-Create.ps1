# Creates the daily "Sentinel WinUpdater" scheduled task.
# Run from the Sentinel install directory (where Sentinel-WinUpdater.exe lives).
$exe = Join-Path $PSScriptRoot "Sentinel-WinUpdater.exe"
& $exe /CreateTask
