#!/usr/bin/env python3
"""Create a Notion sub-page from one plaintext document in .build/out.

The Notion integration token is NEVER hardcoded and is never passed on the
command line (which would leak into shell history). Resolution order:

    1. $NOTION_TOKEN
    2. .repo-credentials  (gitignored, JSON: {"notion_token": "ntn_..."})

Usage:
    python3 tools/notion_create.py --title "12 · Yau / Gödel 人物模块" \
                                   --file .build/out/12_Yau-Gödel_人物模块.md
    python3 tools/notion_create.py --title "..." --file ... --after <block_id>

Prints the new page id and URL. Uses the 2025-09-03 `markdown` parameter,
which lets Notion parse headings / tables / lists server-side.
"""
import argparse, json, os, sys, time, urllib.error, urllib.request

API = 'https://api.notion.com/v1'
VERSION = '2025-09-03'
PARENT_DEFAULT = '3d842c2e-a1bb-801b-9a9f-eb7f60321a0c'

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)


def resolve_token() -> str:
    tok = os.environ.get('NOTION_TOKEN')
    if tok:
        return tok
    cred = os.path.join(ROOT, '.repo-credentials')
    if os.path.exists(cred):
        try:
            data = json.load(open(cred))
        except Exception as e:
            sys.exit(f'could not read {cred}: {e}')
        for key in ('notion_token', 'notion', 'NOTION_TOKEN'):
            if data.get(key):
                return data[key]
        sys.exit(f'{cred} has no "notion_token" key '
                 f'(found: {sorted(data)})')
    sys.exit(
        'no Notion token available.\n'
        '  set NOTION_TOKEN, or add "notion_token" to .repo-credentials'
    )


def api(token, path, method='GET', payload=None, timeout=900):
    req = urllib.request.Request(
        API + path,
        data=json.dumps(payload).encode() if payload is not None else None,
        method=method,
        headers={'Authorization': f'Bearer {token}',
                 'Notion-Version': VERSION,
                 'Content-Type': 'application/json'})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=timeout) as r:
                return json.loads(r.read())
        except urllib.error.HTTPError as e:
            body = e.read().decode()
            if e.code == 429:
                time.sleep(float(e.headers.get('Retry-After', 2)))
                continue
            if e.code >= 500:
                time.sleep(2 ** attempt)
                continue
            raise SystemExit(f'{method} {path} -> HTTP {e.code}\n{body}')
    raise SystemExit(f'{method} {path}: retries exhausted')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--title', required=True)
    ap.add_argument('--file', required=True)
    ap.add_argument('--parent', default=PARENT_DEFAULT)
    ap.add_argument('--after', default=None,
                    help='block id to insert the new page after')
    a = ap.parse_args()

    src = a.file if os.path.isabs(a.file) else os.path.join(ROOT, a.file)
    md = open(src, encoding='utf-8').read()
    token = resolve_token()

    page = api(token, '/pages', 'POST', {
        'parent': {'type': 'page_id', 'page_id': a.parent},
        'properties': {'title': {'title': [
            {'type': 'text', 'text': {'content': a.title}}]}},
        'markdown': md,
    })
    pid, url = page.get('id'), page.get('url')
    print(f'  created {a.title}\n    id  {pid}\n    url {url}')

    if a.after:
        api(token, f'/blocks/{a.parent}/children', 'PATCH',
            {'children': [{'id': pid, 'after': a.after}]})
        print(f'  moved after {a.after}')

    # report block count so a silently-empty page is obvious
    n, cur = 0, None
    while True:
        q = f'/blocks/{pid}/children?page_size=100'
        if cur:
            q += f'&start_cursor={cur}'
        r = api(token, q)
        n += len(r['results'])
        if not r.get('has_more'):
            break
        cur = r['next_cursor']
    print(f'  blocks: {n}')


if __name__ == '__main__':
    main()
