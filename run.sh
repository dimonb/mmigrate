#!/bin/bash

RD=$(dirname "$(readlink -f "$0")")
WORKSPACE=$1
CHATID=$2

mmctl user list --all --json >users.json

if [ -z "$CHATID" ]; then
    echo "Usage: $0 <workspace>(ebac-online) <chatid>"
    exit 1
fi

mkdir -p ./backup/$CHATID
pushd ./backup/$CHATID >/dev/null

if [ ! -f mm-export.zip ]; then
    echo "Downloading mm-export.zip"
    $RD/slackdump -export mm-export.zip -export-type mattermost -download $CHATID
fi

if [ ! -f mattermost_import_slack.jsonl ]; then
    echo "Do transformations"
    $RD/mmetl transform slack -t $WORKSPACE -d data -f mm-export.zip -o mattermost_import_slack.jsonl
fi

echo "Process mattermost_import_slack.jsonl"
USERS=$(python3 $RD/fix_users.py $RD/users.json ./mattermost_import_slack.jsonl ./mattermost_import.jsonl)

python3 $RD/split_large.py ./mattermost_import.jsonl

for f in $(ls -1d chunk_*); do
    echo "Processing $f"
    pushd $f >/dev/null

    ZIPFILE="bulk_import_${CHATID}_${f}.zip"
    rm -f $ZIPFILE
    zip -r $ZIPFILE data mattermost_import.jsonl
    IMPORT_ID=$(mmctl import upload $ZIPFILE | grep 'ID' | awk -F ':' '{print $2}' | xargs)

    if [ -z "$IMPORT_ID" ]; then
        echo "Failed to upload $ZIPFILE"
        exit 1
    fi

    mmctl import process "${IMPORT_ID}_${ZIPFILE}"

    popd 
done

python3 $RD/add_channel_users.py ./mattermost_import.jsonl
#
#
#

