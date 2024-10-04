$RD = Split-Path -Parent -Path $MyInvocation.MyCommand.Path
$XOXTOKEN = Get-Content "$RD\.xoxptoken"
$WORKSPACE = $args[0]
$CHATID = $args[1]

if (-not $WORKSPACE) {
    Write-Output "Usage: send_completed.ps1 <workspace>(ebac-online) <chatid>"
    exit 1
}

if (-not $CHATID) {
    Write-Output "Usage: send_completed.ps1 <workspace>(ebac-online) <chatid>"
    exit 1
}

# Get channel name
$response = Invoke-RestMethod -Method Get -Uri "https://slack.com/api/conversations.info?channel=$CHATID" -Headers @{"Authorization" = "Bearer $XOXTOKEN"}
$CNAME = $response.channel.name

Write-Output "Channel name: $CNAME"

# Check the number of posts using mmctl
$POST_COUNT = & mmctl post list -n 150 "${WORKSPACE}:$CNAME" 2>&1

# Handle "Error: Unable to find channel"
if ($POST_COUNT -like "*Error: Unable to find channel*") {
    Write-Output "Channel not found by name, trying with CHATID in lowercase."
    
    # Use CHATID in lowercase and retry
    $CNAME_LOWER = $CHATID.ToLower()
    $POST_COUNT = & mmctl post list -n 150 "${WORKSPACE}:$CNAME_LOWER" 2>&1

    if ($POST_COUNT -like "*Error: Unable to find channel*") {
        Write-Output "Channel still not found with CHATID in lowercase. Exiting."
        exit 1
    }

    # If found with lowercase, update channel display name
    Write-Output "Channel found with CHATID in lowercase. Updating display name to $CNAME."
    & mmctl channel rename --display-name "$CNAME" "${WORKSPACE}:$CNAME_LOWER"
    $CNAME = $CNAME_LOWER
}

# Continue if the channel is found
$POST_COUNT = ($POST_COUNT -split "`n" | Where-Object { $_ -notmatch "added to the channel|joined the channel" }).Count
Write-Output "Number of posts in the channel: $POST_COUNT"

# If there are fewer than 10 posts, exit without sending the message
if ($POST_COUNT -le 10) {
    Write-Output "Not enough posts in the channel. Exiting without sending the message."
    exit 0
}

Write-Output "More than 10 posts found. Proceeding with message."

# Send message to the channel
$MESSAGE = "http://mm.ebac.app/$WORKSPACE/channels/$CNAME migrated to mm"

# Send the message and capture the HTTP status code
$tempFile = New-TemporaryFile
$response = Invoke-WebRequest -Uri "https://slack.com/api/chat.postMessage" -Method Post -Headers @{"Authorization" = "Bearer $XOXTOKEN"; "Content-type" = "application/json"} -Body (@{
    "channel" = "$CHATID"
    "text" = "$MESSAGE"
} | ConvertTo-Json) -OutFile $tempFile.FullName -UseBasicParsing

# Check if response is 200, otherwise show the error
if ($response.StatusCode -ne 200) {
    Write-Output "Failed to send message. HTTP response code: $($response.StatusCode)"
    Get-Content $tempFile.FullName
} else {
    Write-Output "Message sent successfully: $MESSAGE"
}

# Clean up temporary file
Remove-Item $tempFile.FullName