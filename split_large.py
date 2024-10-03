import json
import sys
import os
import shutil


INPUT = sys.argv[1]
MAX_SIZE = 50*1024*1024

base_dir = os.path.dirname(INPUT)
input_name = os.path.basename(INPUT)
mm_json = [json.loads(m) for m in open(INPUT).readlines()]

known_types = {'version', 'channel', 'user', 'post', 'direct_post', 'direct_channel'}
assert {m['type'] for m in mm_json} not in {'version', 'channel', 'user', 'post', 'direct_post', 'direct_channel'}, 'Unexpected message type %s'%(set(m['type'] for m in mm_json),)
header = [m for m in mm_json if m['type'] in ('version', 'channel', 'user', 'direct_channel')]

chunks = [[]]
current_size_sum = 0
for i, m in enumerate(mm_json):
    if m['type'] in ('post', 'direct_post'):
        for attach in m[m['type']]['attachments']:
             fl = os.path.join(base_dir, 'data', attach['path'])
             if os.path.exists(fl):
                 current_size_sum += os.path.getsize(fl)    
        chunks[-1].append(m)
    if current_size_sum > MAX_SIZE:
        chunks.append([])
        current_size_sum = 0

for i, chunk in enumerate(chunks):
    chpath = os.path.join(base_dir, f'chunk_{i}')
    os.makedirs(chpath, exist_ok=True)
    with open(os.path.join(chpath, input_name), 'wt') as out:
        for m in header + chunk:
            print(json.dumps(m), file=out)
    os.makedirs(os.path.join(chpath, 'data'), exist_ok=True)
    for m in chunk:
        if m['type'] in ('post', 'direct_post'):
            for attach in m[m['type']]['attachments']:
                fl = os.path.join(base_dir, 'data', attach['path'])
                if os.path.exists(fl):
                    os.makedirs(os.path.join(chpath, 'data', os.path.dirname(attach['path'])), exist_ok=True)
                    shutil.copy(fl, os.path.join(chpath, 'data', attach['path']))

            for reply in m[m['type']]['replies']:
                for attach in reply['attachments']:
                    fl = os.path.join(base_dir, 'data', attach['path'])
                    if os.path.exists(fl):
                        os.makedirs(os.path.join(chpath, 'data', os.path.dirname(attach['path'])), exist_ok=True)
                        shutil.copy(fl, os.path.join(chpath, 'data', attach['path']))
