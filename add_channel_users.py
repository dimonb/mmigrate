import argparse
import json
import subprocess

def main():
    parser = argparse.ArgumentParser(description='Generate and execute mmctl commands from JSONL file.')
    parser.add_argument('input_file', help='Path to the JSONL input file')
    args = parser.parse_args()

    input_file = args.input_file

    # Set to store unique users
    users_set = set()

    # Variable to hold channel information
    channels = []

    # Read the file and process entries
    with open(input_file, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            entry = json.loads(line)
            entry_type = entry.get('type')

            if entry_type == 'user':
                # Collect usernames from user entries
                user_info = entry.get('user', {})
                username = user_info.get('username')
                if username:
                    users_set.add(username)
            elif entry_type == 'post':
                # Collect usernames from post entries
                post_info = entry.get('post', {})
                user = post_info.get('user')
                if user:
                    users_set.add(user)
                # Collect usernames from replies
                for reply in post_info.get('replies', []):
                    reply_user = reply.get('user')
                    if reply_user:
                        users_set.add(reply_user)
            elif entry_type == 'direct_post':
                # Collect usernames from direct posts
                direct_post_info = entry.get('direct_post', {})
                user = direct_post_info.get('user')
                if user:
                    users_set.add(user)
                for reply in direct_post_info.get('replies', []):
                    reply_user = reply.get('user')
                    if reply_user:
                        users_set.add(reply_user)
            elif entry_type == 'direct_channel':
                # Collect users from direct_channel entries
                members = entry.get('direct_channel', {}).get('members', [])
                for member in members:
                    if member:
                        users_set.add(member)
            elif entry_type == 'channel':
                # Collect channel information
                channel_info = entry.get('channel', {})
                team = channel_info.get('team')
                name = channel_info.get('name')
                if team and name:
                    channels.append(f"{team}:{name}")

    # Convert the set of users to a sorted list
    users = sorted(users_set)

    # Generate and execute mmctl commands for each channel
    for channel_identifier in channels:

        command = ['mmctl', 'channel', 'create', '--team', channel_identifier.split(':')[0], '--name', channel_identifier.split(':')[1], '--private', '--display-name', channel_identifier.split(':')[1]]
        result = subprocess.run(command, check=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        print(f"Output:\n{result.stdout}")
        print(f"Error message:\n{result.stderr}")

        # Split users into batches of up to 10
        batch_size = 10
        for i in range(0, len(users), batch_size):
            user_batch = users[i:i+batch_size]
            # Construct the mmctl command
            users_str = ' '.join(user_batch)
            command = ['mmctl', 'channel', 'users', 'add', channel_identifier] + user_batch
            # Execute the command
            try:
                result = subprocess.run(command, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                print(f"Command executed successfully: {' '.join(command)}")
            except subprocess.CalledProcessError as e:
                print(f"An error occurred while executing: {' '.join(command)}")
                print(f"Output:\n{result.stdout}")
                print(f"Error message:\n{e.stderr}")

if __name__ == '__main__':
    main()
