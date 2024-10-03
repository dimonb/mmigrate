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
CNAME=$(curl -X GET "https://slack.com/api/conversations.info?channel=$CHATID" \
-H "Authorization: Bearer $XOXTOKEN" | jq -r '.channel.name')

echo "Channel name: $CNAME"

# Check the number of posts using mmctl
POST_COUNT=$(mmctl post list -n 150 $WORKSPACE:$CNAME | grep -v "added to the channel" | grep -v "joined the channel" | wc -l)

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
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST https://slack.com/api/chat.postMessage \
-H "Authorization: Bearer $XOXTOKEN" \
-H "Content-type: application/json" \
--data "{
    \"channel\": \"$CHATID\",
    \"text\": \"$MESSAGE\"
}")

# Check if response is 200, otherwise show the error
if [ "$RESPONSE" -ne 200 ]; then
    echo "Failed to send message. HTTP response code: $RESPONSE"
    curl -X POST https://slack.com/api/chat.postMessage \
    -H "Authorization: Bearer $XOXTOKEN" \
    -H "Content-type: application/json" \
    --data "{
        \"channel\": \"$CHATID\",
        \"text\": \"$MESSAGE\"
    }"
else
    echo "Message sent successfully: $MESSAGE"
fi
