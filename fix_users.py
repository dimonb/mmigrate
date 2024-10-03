import json
import argparse

def main():
    parser = argparse.ArgumentParser(description='Process Mattermost JSON export.')
    parser.add_argument('USERS', help='Path to the users JSON file')
    parser.add_argument('INPUT', help='Path to the input JSON lines file')
    parser.add_argument('OUTPUT', help='Path to the output file')

    args = parser.parse_args()

    USERS = args.USERS
    INPUT = args.INPUT
    OUTPUT = args.OUTPUT

    users = json.load(open(USERS))

    out = open(OUTPUT, 'wt')

    email_user_map = {
        u['email'].lower(): u['username']
        for u in users
    }

    mm_json = [json.loads(m) for m in open(INPUT).readlines()]
    mm_email_user_map = {
        m['user']['username']: m['user']['email'].lower()
        for m in mm_json
        if m['type'] == 'user'
    }

    collect_new_users = set()
    for m in mm_json:
        if m['type'] == 'post':
            collect_new_users.add(m['post']['user'])
            for r in m['post']['replies']:
                collect_new_users.add(r['user'])
        if m['type'] == 'direct_channel':
            collect_new_users.update(m['direct_channel']['members'])

    for m in mm_json:
        if m['type'] == 'channel':
            m['channel']['type'] = 'P'
        if m['type'] == 'user' and m['user']['username'] in collect_new_users:
            if m['user']['email'].lower() not in email_user_map:
                email_user_map[m['user']['email'].lower()] = m['user']['username']
            m['user']['username'] = email_user_map[m['user']['email'].lower()]
            for field in ['roles', 'teams', 'nickname', 'locale', 'auth_service', 'position']:
                m['user'].pop(field, None)
            print(json.dumps(m), file=out)
        if m['type'] == 'user':
            continue
        if m['type'] in ('post', 'direct_post'):
            m[m['type']]['user'] = email_user_map[mm_email_user_map[m[m['type']]['user']]]
            for r in m[m['type']]['replies']:
                r['user'] = email_user_map[mm_email_user_map[r['user']]]
        if m['type'] == 'direct_channel':
            m['direct_channel']['members'] = [
                email_user_map[mm_email_user_map[u]] for u in m['direct_channel']['members']
            ]
        if m['type'] == 'direct_post':
            m['direct_post']['channel_members'] = [
                email_user_map[mm_email_user_map[u]] for u in m['direct_post']['channel_members']
            ]
        print(json.dumps(m), file=out)

if __name__ == '__main__':
    main()
