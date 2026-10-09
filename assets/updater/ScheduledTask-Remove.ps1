# Removes the "Sentinel WinUpdater" scheduled task.
$exe = Join-Path $PSScriptRoot "Sentinel-WinUpdater.exe"
& $exe /RemoveTask
