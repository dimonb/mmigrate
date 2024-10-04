# Define variables
$RD = Split-Path -Parent -Path (Get-Item -Path $MyInvocation.MyCommand.Definition).FullName
$WORKSPACE = $args[0]
$CHATID = $args[1]

# Check if CHATID is provided
if (-not $CHATID) {
    Write-Output "Usage: $($MyInvocation.MyCommand.Name) <workspace>(ebac-online) <chatid>"
    exit 1
}

# Create directories and navigate
mmctl user list --all --json | Out-File -FilePath users.json

$backupPath = "./backup/$CHATID"
New-Item -ItemType Directory -Force -Path $backupPath
Push-Location -Path $backupPath

# Download export file if not already present
if (-not (Test-Path -Path "mm-export.zip")) {
    Write-Output "Downloading mm-export.zip"
    & "$RD/slackdump" -export "mm-export.zip" -export-type "mattermost" -download $CHATID
}

# Perform transformations if required file is not present
if (-not (Test-Path -Path "mattermost_import_slack.jsonl")) {
    Write-Output "Do transformations"
    & "$RD/mmetl" transform slack -t $WORKSPACE -d data -f "mm-export.zip" -o "mattermost_import_slack.jsonl"
}

# Process the import file
Write-Output "Process mattermost_import_slack.jsonl"
$USERS = & "python3" "$RD/fix_users.py" "$RD/users.json" "./mattermost_import_slack.jsonl" "./mattermost_import.jsonl"

# Split the large file and process chunks
& "python3" "$RD/split_large.py" "./mattermost_import.jsonl"

Get-ChildItem -Filter "chunk_*" | ForEach-Object {
    $chunkFolder = $_.FullName
    Write-Output "Processing $chunkFolder"
    Push-Location -Path $chunkFolder

    $ZIPFILE = "bulk_import_${CHATID}_${($_.Name)}.zip"
    Remove-Item -Path $ZIPFILE -Force -ErrorAction SilentlyContinue
    Compress-Archive -Path @("data", "mattermost_import.jsonl") -DestinationPath $ZIPFILE

    $IMPORT_ID = & "mmctl" import upload $ZIPFILE | Select-String 'ID' | ForEach-Object { ($_ -split ':')[1].Trim() }

    if (-not $IMPORT_ID) {
        Write-Output "Failed to upload $ZIPFILE"
        exit 1
    }

    & "mmctl" import process "${IMPORT_ID}_${ZIPFILE}"
    Pop-Location
}

# Add users to channel
& "python3" "$RD/add_channel_users.py" "./mattermost_import.jsonl"