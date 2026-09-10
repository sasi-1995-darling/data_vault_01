param (
    [switch]$Help,
    [switch]$DiffOnly,
    [switch]$BuildOnly,
    [switch]$FullRefresh,
    [switch]$Upstream,
    [switch]$Downstream
)

function Show-Help {
    Write-Output "Usage: .\buildlist.ps1 [options]"
    Write-Output ""
    Write-Output "Options:"
    Write-Output "  -h              Show this help message"
    Write-Output "  --diff-only     Show only the diff of .sql files"
    Write-Output "  --build-only    Show only the dbt build command"
    Write-Output "  --full-refresh  Include the --full-refresh flag in the dbt build command"
    Write-Output "  --upstream      Include the + before each SQL file to build all upstream dependencies"
    Write-Output "  --downstream    Include the + after each SQL file to build all downstream dependencies"
    Write-Output "  (no options)    Show both the diff and the dbt build command"
}

if ($Help) {
    Show-Help
    exit 0
}

# Fetch the latest changes from the remote repository
git fetch origin

# Get the root directory of the repository
$repoRoot = git rev-parse --show-toplevel

# Get the list of changed .sql files
$changedFiles = git -C $repoRoot diff --name-only origin/main | Select-String -Pattern '\.sql$' | ForEach-Object { $_.Line }

if ($changedFiles.Count -eq 0) {
    Write-Output "No changes detected. There are no .sql files to build."
    exit 0
}

if ($DiffOnly -or -not $BuildOnly) {
    Write-Output "Changed .sql files:"
    $changedFiles | ForEach-Object { Write-Output "  $_" }
    Write-Output ""
}

if ($BuildOnly -or -not $DiffOnly) {
    # Construct the dbt build command
    $dbtCommand = "dbt build --select"
    foreach ($file in $changedFiles) {
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($file)
        $prefix = if ($Upstream) { "+" } else { "" }
        $suffix = if ($Downstream) { "+" } else { "" }
        $dbtCommand += " $prefix$fileName$suffix"
    }

    # Add the --full-refresh flag if specified
    if ($FullRefresh) {
        $dbtCommand += " --full-refresh"
    }

    # Output the dbt build command
    Write-Output "DBT Build Command:"
    Write-Output "  $dbtCommand --exclude 'ref_business_key_collision'"
}

if (-not $DiffOnly -and -not $BuildOnly) {
    Write-Output ""
    Write-Output "Both diff and build command shown above."
}