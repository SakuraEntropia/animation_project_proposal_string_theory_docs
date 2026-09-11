#!/usr/bin/env python3
"""
Push the worldbuilding document set to Notion.

Usage:
    export NOTION_TOKEN=ntn_...        # internal integration secret
    export NOTION_PARENT_PAGE_ID=...   # the page to create sub-pages under
    python3 tools/notion_push.py

The integration must be granted access to the parent page
(page -> ... -> Connections -> add your integration).

Note: Notion's API caps a single request at 100 blocks, so documents are
appended in chunks. Tables become Notion `table` blocks.
"""
import json, os, re, sys, time, urllib.request, urllib.error

API = 'https://api.notion.com/v1'
VERSION = '2022-06-28'
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SRC = os.path.join(ROOT, '.build', 'out')


def api(method, path, payload=None):
    url = f'{API}{path}'
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(url, data=data, method=method, headers={
        'Authorization': f'Bearer {TOKEN}',
        'Notion-Version': VERSION,
        'Content-Type': 'application/json',
    })
    for attempt in range(5):
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
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


def rich(text, bold=False, code=False, italic=False):
    return {'type': 'text', 'text': {'content': text[:2000]},
            'annotations': {'bold': bold, 'code': code, 'italic': italic}}


def rt(inline):
    """Parse **bold**, `code`, *italic* into rich_text objects."""
    out, i = [], 0
    pat = re.compile(r'(\*\*.+?\*\*|`[^`]+`|\*[^*]+\*)')
    for part in pat.split(inline):
        if not part: continue
        if part.startswith('**') and part.endswith('**') and len(part) > 4:
            out.append(rich(part[2:-2], bold=True))
        elif part.startswith('`') and part.endswith('`') and len(part) > 2:
            out.append(rich(part[1:-1], code=True))
        elif part.startswith('*') and part.endswith('*') and len(part) > 2:
            out.append(rich(part[1:-1], italic=True))
        else:
            out.append(rich(part))
    return out or [rich('')]


def table_block(rows):
    """rows: list of list[str]; first row is the header."""
    width = max(len(r) for r in rows)
    rows = [r + [''] * (width - len(r)) for r in rows]
    children = [{
        'object': 'block', 'type': 'table_row',
        'table_row': {'cells': [rt(c) for c in r]},
    } for r in rows]
    return {
        'object': 'block', 'type': 'table',
        'table': {
            'table_width': width,
            'has_column_header': True,
            'has_row_header': False,
            'children': children,
        },
    }


def md_to_blocks(md):
    lines = md.split('\n')
    blocks, i = [], 0
    while i < len(lines):
        ln = lines[i]
        s = ln.rstrip()

        # HTML comment (source header)
        if s.strip().startswith('<!--'):
            while i < len(lines) and '-->' not in lines[i]:
                i += 1
            i += 1
            continue

        # fenced code
        if s.strip().startswith('```'):
            i += 1
            buf = []
            while i < len(lines) and not lines[i].strip().startswith('```'):
                buf.append(lines[i]); i += 1
            i += 1
            blocks.append({'object': 'block', 'type': 'code',
                           'code': {'rich_text': [rich('\n'.join(buf))], 'language': 'plain text'}})
            continue

        # table
        if s.strip().startswith('|') and i + 1 < len(lines) and \
           re.match(r'^\s*\|[\s:|-]+\|\s*$', lines[i + 1]):
            rows = []
            while i < len(lines) and lines[i].strip().startswith('|'):
                cells = [c.strip() for c in lines[i].strip().strip('|').split('|')]
                if not re.match(r'^[\s:|-]+$', lines[i].strip().strip('|')):
                    rows.append(cells)
                i += 1
            if rows:
                blocks.append(table_block(rows))
            continue

        t = s.strip()
        if not t:
            i += 1; continue
        if t in ('---', '***', '___'):
            blocks.append({'object': 'block', 'type': 'divider', 'divider': {}})
            i += 1; continue

        m = re.match(r'^(#{1,3})\s+(.*)$', t)
        if m:
            lvl = len(m.group(1))
            typ = {1: 'heading_1', 2: 'heading_2', 3: 'heading_3'}[lvl]
            blocks.append({'object': 'block', 'type': typ, typ: {'rich_text': rt(m.group(2))}})
            i += 1; continue

        if t.startswith('> '):
            buf = []
            while i < len(lines) and lines[i].strip().startswith('>'):
                buf.append(lines[i].strip().lstrip('>').strip()); i += 1
            blocks.append({'object': 'block', 'type': 'quote',
                           'quote': {'rich_text': rt(' '.join(x for x in buf if x))}})
            continue

        m = re.match(r'^[-*]\s+(.*)$', t)
        if m:
            blocks.append({'object': 'block', 'type': 'bulleted_list_item',
                           'bulleted_list_item': {'rich_text': rt(m.group(1))}})
            i += 1; continue

        m = re.match(r'^(\d+)\.\s+(.*)$', t)
        if m:
            blocks.append({'object': 'block', 'type': 'numbered_list_item',
                           'numbered_list_item': {'rich_text': rt(m.group(2))}})
            i += 1; continue

        blocks.append({'object': 'block', 'type': 'paragraph',
                       'paragraph': {'rich_text': rt(t)}})
        i += 1
    return blocks


def push_doc(parent_id, title, md):
    page = api('POST', '/pages', {
        'parent': {'type': 'page_id', 'page_id': parent_id},
        'properties': {'title': [{'type': 'text', 'text': {'content': title}}]},
    })
    pid = page['id']
    blocks = md_to_blocks(md)
    for k in range(0, len(blocks), 90):
        api('PATCH', f'/blocks/{pid}/children', {'children': blocks[k:k + 90]})
        time.sleep(0.4)
    return pid, len(blocks)


if __name__ == '__main__':
    TOKEN = os.environ.get('NOTION_TOKEN')
    PARENT = os.environ.get('NOTION_PARENT_PAGE_ID')
    if not TOKEN:
        sys.exit('NOTION_TOKEN is not set')
    if not PARENT:
        sys.exit('NOTION_PARENT_PAGE_ID is not set')
    files = sorted(f for f in os.listdir(SRC) if f.endswith('.md'))
    if not files:
        sys.exit(f'no source documents in {SRC} (run tools/gen.py first)')
    print(f'pushing {len(files)} documents to Notion page {PARENT}\n')
    for name in files:
        title = name[:-3].split('_', 1)[-1].replace('_', ' · ')
        md = open(os.path.join(SRC, name), encoding='utf-8').read()
        pid, n = push_doc(PARENT, title, md)
        print(f'  ✓ {title:28s} {n:4d} blocks  ({pid})')
    print('\ndone')
