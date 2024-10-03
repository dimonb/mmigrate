#!/bin/bash

RD=$(dirname "$(readlink -f "$0")")
XOXTOKEN=$(cat $RD/.xoxptoken)
CHATID=$1

if [ -z "$CHATID" ]; then
    echo "Usage: $0 <chatid>" >&2
    exit 1
fi

# Check access to the channel using conversations.info
RESPONSE=$(curl -s -X GET "https://slack.com/api/conversations.info?channel=$CHATID" \
-H "Authorization: Bearer $XOXTOKEN")

# Check if access is denied
if [[ $(echo "$RESPONSE" | jq -r '.ok') != "true" ]]; then
    ERROR_MSG=$(echo "$RESPONSE" | jq -r '.error')
    echo "Error: No access to chat ID $CHATID. Reason: $ERROR_MSG" >&2
    exit 1
fi

echo "Access to chat ID $CHATID is successful."
exit 0
