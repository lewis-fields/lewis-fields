# 1. Use Get-Process instead of taskkill.exe to kill OneDrive and Explorer.
Get-Process -Name OneDrive -ErrorAction SilentlyContinue | Stop-Process
Get-Process -Name explorer -ErrorAction SilentlyContinue | Stop-Process
New-Item -ItemType Directory -Path $tempDir
# 2. Use a temporary directory for copying OneDrive contents.
$tempDir = Join-Path $env:TEMP "OneDriveBackup"
Robocopy $OneDrivePath $UserProfilePath /S /E /DCOPY:DA /COPY:DAT /PURGE /MIR /R:1000000 /W:30 /XD Documents

# Get the OneDrive app package for the current user
$oneDrivePackage = Get-AppxPackage -Name *OneDrive*

# Remove the OneDrive app package
if ($oneDrivePackage) {
    Remove-AppxPackage -Package $oneDrivePackage.PackageFullName
} else {
    Write-Host "OneDrive package not found for the current user."
}

# 4. Use Uninstall-AppxProvisionedPackage instead of winget for uninstalling OneDrive.
Remove-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Name "System.IsPinnedToNameSpaceTree"
Remove-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Name "System.IsPinnedToNameSpaceTree"

# 5. Use Remove-Item with -recurse and -force options for safe removal.
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue (
    "$env:localappdata\Microsoft\OneDrive",
    "$env:programdata\Microsoft OneDrive",
    "$env:systemdrive\OneDriveTemp",
    "$env:USERPROFILE\OneDrive" # Remove only if it's empty after copying
) -Confirm:$false

# Remove OneDrive from the Explorer sidebar
Remove-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Name "System.IsPinnedToNameSpaceTree" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Name "System.IsPinnedToNameSpaceTree" -ErrorAction SilentlyContinue

# 7. Use Unregister-ScheduledTask with -Confirm:$false for silent removal of scheduled tasks.
Get-ScheduledTask -TaskPath '\\' -TaskName 'OneDrive*' -ea SilentlyContinue | Unregister-ScheduledTask -Confirm:$false

# 8. Restore default Shell folders locations using Registry keys.
$userShellFolders = @{
    "AppData" = "$env:userprofile\AppData\Roaming"
    "Cache" = "$env:userprofile\AppData\Local\Microsoft\Windows\INetCache"
    "Cookies" = "$env:userprofile\AppData\Local\Microsoft\Windows\INetCookies"
    "Favorites" = "$env:userprofile\Favorites"
    "History" = "$env:userprofile\AppData\Local\Microsoft\Windows\History"
    "Local AppData" = "$env:userprofile\AppData\Local"
    "My Music" = "$env:userprofile\Music"
    "My Video" = "$env:userprofile\Videos"
    "NetHood" = "$env:userprofile\AppData\Roaming\Microsoft\Windows\Network Shortcuts"
    "PrintHood" = "$env:userprofile\AppData\Roaming\Microsoft\Windows\Printer Shortcuts"
    "Programs" = "$env:userprofile\AppData\Roaming\Microsoft\Windows\Start Menu\Programs"
    "Recent" = "$env:userprofile\AppData\Roaming\Microsoft\Windows\Recent"
    "SendTo" = "$env:userprofile\AppData\Roaming\Microsoft\Windows\SendTo"
    "Start Menu" = "$env:userprofile\AppData\Roaming\Microsoft\Windows\Start Menu"
    "Startup" = "$env:userprofile\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
    "Templates" = "$env:userprofile\AppData\Roaming\Microsoft\Windows\Templates"
    "{374DE290-123F-4565-9164-39C4925E467B}" = "$env:userprofile\Downloads"
    "Desktop" = "$env:userprofile\Desktop"
    "My Pictures" = "$env:userprofile\Pictures"
    "Personal" = "$env:userprofile\Documents"
    "{F42EE2D3-909F-4907-8871-4C22FC0BF756}" = "$env:userprofile\Documents"
}

# Loop through the hashtable and set the registry keys
foreach ($key in $userShellFolders.Keys) {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name $key -Value $userShellFolders[$key]
}




