RD=$(dirname "$(readlink -f "$0")")
XOXTOKEN=$(cat $RD/.xoxptoken)
WORKSPACE=$1
CHATID=$2

if [ -z "$WORKSPACE" ]; then
    echo "Usage: $0 <workspace>(ebac-online) <chatid>"
    exit 1
fi

if [ -z "$CHATID" ]; then
    echo "Usage: $0 <workspace>(ebac-online) <chatid>"
    exit 1
fi

# Get channel name
CNAME=$(curl -s -X GET "https://slack.com/api/conversations.info?channel=$CHATID" \
-H "Authorization: Bearer $XOXTOKEN" | jq -r '.channel.name')

echo "Channel name: $CNAME"

# Check the number of posts using mmctl
POST_COUNT=$(mmctl post list -n 150 $WORKSPACE:$CNAME 2>&1)

# Handle "Error: Unable to find channel"
if [[ "$POST_COUNT" == *"Error: Unable to find channel"* ]]; then
    echo "Channel not found by name, trying with CHATID in lowercase."
    
    # Use CHATID in lowercase and retry
    CNAME_LOWER=$(echo "$CHATID" | tr '[:upper:]' '[:lower:]')
    POST_COUNT=$(mmctl post list -n 150 $WORKSPACE:$CNAME_LOWER 2>&1)

    if [[ "$POST_COUNT" == *"Error: Unable to find channel"* ]]; then
        echo "Channel still not found with CHATID in lowercase. Exiting."
        exit 1
    fi

    # If found with lowercase, update channel display name
    echo "Channel found with CHATID in lowercase. Updating display name to $CNAME."
    mmctl channel rename --display-name "$CNAME" $WORKSPACE:$CNAME_LOWER
    CNAME=$CNAME_LOWER
fi

# Continue if the channel is found
POST_COUNT=$(echo "$POST_COUNT" | grep -v "added to the channel" | grep -v "joined the channel" | wc -l)
echo "Number of posts in the channel: $POST_COUNT"

# If there are fewer than 10 posts, exit without sending the message
if [ "$POST_COUNT" -le 10 ]; then
    echo "Not enough posts in the channel. Exiting without sending the message."
    exit 0
fi

echo "More than 10 posts found. Proceeding with message."

# Send message to the channel
MESSAGE="http://mm.ebac.app/$WORKSPACE/channels/$CNAME migrated to mm"

# Send the message and capture the HTTP status code
TMPFILE=$(mktemp)
HTTP_RESPONSE=$(curl -s -o "$TMPFILE" -w "%{http_code}" -X POST https://slack.com/api/chat.postMessage \
-H "Authorization: Bearer $XOXTOKEN" \
-H "Content-type: application/json" \
--data "{
    \"channel\": \"$CHATID\",
    \"text\": \"$MESSAGE\"
}")

# Check if response is 200, otherwise show the error
if [ "$HTTP_RESPONSE" -ne 200 ]; then
    echo "Failed to send message. HTTP response code: $HTTP_RESPONSE"
    cat "$TMPFILE"
else
    echo "Message sent successfully: $MESSAGE"
fi

# Clean up temporary file
rm "$TMPFILE"