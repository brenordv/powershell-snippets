<#
.SYNOPSIS
This script performs a one-way synchronization of files from a source directory to a target directory, ensuring data integrity by comparing file hashes.
It supports resuming interrupted operations using a progress tracking file.

.DESCRIPTION
The script copies files from a specified source directory to a target directory. Before copying, it checks if the file already exists in the target directory
and compares their hashes to determine if the copy is necessary. If the hashes match, the file is skipped to save time and resources.
The script supports multiple hash algorithms (MD5, SHA1, SHA256) for comparison.

Progress is tracked in a JSON file, allowing the script to resume from where it left off in case of interruptions.
Logs are maintained in a specified log file for auditing and debugging purposes.

.PARAMETER SourceDir
The source directory containing the files to be copied. Defaults to `C:\folderA`.

.PARAMETER TargetDir
The target directory where the files will be copied. Defaults to `C:\folderB`.

.PARAMETER LogFile
The path to the log file where the script writes its operation logs. Defaults to `C:\copy_log.txt`.

.PARAMETER ProgressFile
The path to the JSON file used for tracking progress. Defaults to `C:\copy_progress.json`.

.PARAMETER HashAlgorithm
The hash algorithm used for file comparison. Supported values are "MD5", "SHA1", and "SHA256". Defaults to "MD5".

.EXAMPLES
# Example 1: Basic usage with default parameters (not very useful, but still...)
.\CopyFilesWithHashCheck.ps1

# Example 2: Specify custom source and target directories
.\CopyFilesWithHashCheck.ps1 -SourceDir "D:\Source" -TargetDir "D:\Backup"

# Example 3: Use SHA256 for hash comparison
.\CopyFilesWithHashCheck.ps1 -HashAlgorithm "SHA256"

# Example 4: Specify custom log and progress files
.\CopyFilesWithHashCheck.ps1 -LogFile "D:\Logs\copy_log.txt" -ProgressFile "D:\Logs\copy_progress.json"

.NOTES

#>

param (
    [string]$SourceDir = "C:\folderA",
    [string]$TargetDir = "C:\folderB",
    [string]$LogFile = "C:\copy_log.txt",
    [string]$ProgressFile = "C:\copy_progress.json",
    [ValidateSet("MD5", "SHA1", "SHA256")]
    [string]$HashAlgorithm = "MD5"
)

# Ensure source and target directories exist
if (-not (Test-Path $SourceDir)) { throw "Source directory does not exist: $SourceDir" }
if (-not (Test-Path $TargetDir)) { New-Item -ItemType Directory -Path $TargetDir | Out-Null }

# Load or initialize progress tracking
$progress = @{}
if (Test-Path $ProgressFile) {
    try {
        $rawProgress = Get-Content $ProgressFile -Raw | ConvertFrom-Json
        $progress = @{}
        foreach ($entry in $rawProgress.PSObject.Properties) {
            $progress[$entry.Name] = $entry.Value
        }
    } catch {
        Write-Warning "Progress file is corrupted. Starting fresh."
        $progress = @{}
    }
}

function Write-Log($message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Tee-Object -FilePath $LogFile -Append
}

function Get-RelativePath($base, $fullPath) {
    return $fullPath.Substring($base.Length).TrimStart('\')
}

# Recursively get all files from the source directory
$files = Get-ChildItem -Path $SourceDir -Recurse -File

foreach ($file in $files) {
    $relativePath = Get-RelativePath $SourceDir $file.FullName

    # Skip if already processed
    if ($progress.ContainsKey($relativePath)) {
        Write-Log "Skipping (already processed): $relativePath"
        continue
    }

    $destinationPath = Join-Path $TargetDir $relativePath
    $destinationDir = Split-Path $destinationPath -Parent

    if (-not (Test-Path $destinationDir)) {
        New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
    }

    $copyNeeded = $true

    if (Test-Path $destinationPath) {
        $sourceHash = Get-FileHash -Path $file.FullName -Algorithm $HashAlgorithm
        $destHash = Get-FileHash -Path $destinationPath -Algorithm $HashAlgorithm

        if ($sourceHash.Hash -eq $destHash.Hash) {
            Write-Log "Skipping (identical hash - $HashAlgorithm): $relativePath"
            $copyNeeded = $false
        } else {
            Write-Log "Overwriting (different hash - $HashAlgorithm): $relativePath"
        }
    } else {
        Write-Log "Copying (new file): $relativePath"
    }

    if ($copyNeeded) {
        try {
            Copy-Item -Path $file.FullName -Destination $destinationPath -Force
        } catch {
            Write-Log "ERROR copying ${relativePath}: ${$_}"
            continue
        }
    }

    # Save progress
    $progress[$relativePath] = @{
        Copied = $true
        Timestamp = (Get-Date).ToString("o")
        HashAlgorithm = $HashAlgorithm
    }
    $progress | ConvertTo-Json -Depth 3 | Set-Content -Path $ProgressFile
}

Write-Log "✅ Operation complete using hash: $HashAlgorithm"
