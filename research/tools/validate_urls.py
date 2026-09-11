#!/usr/bin/env python3
"""Validate every cited URL. Drops/annotates dead ones so no fabricated source survives."""
import json, glob, subprocess, sys, concurrent.futures as cf

UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/120 Safari/537.36")

def check(u):
    for attempt in (1, 2):
        try:
            r = subprocess.run(
                ['curl','-sS','-o','/dev/null','-w','%{http_code}','-L','--max-time','20',
                 '-A',UA, '--compressed', u],
                capture_output=True, text=True, timeout=30)
            code = r.stdout.strip()
            if code.isdigit() and code != '000':
                return u, code
        except Exception:
            pass
    return u, 'ERR'

files = sorted(glob.glob('data/crosscultural*.json'))
works = []
for f in files:
    works += json.load(open(f))

urls = sorted({c['url'] for r in works for c in r['claims']})
print(f"validating {len(urls)} unique URLs from {len(files)} files ...", file=sys.stderr)

res = {}
with cf.ThreadPoolExecutor(max_workers=10) as ex:
    for u, code in ex.map(check, urls):
        res[u] = code

live = sum(1 for c in res.values() if c.startswith('2'))
print(f"\nlive(2xx): {live}/{len(urls)}")
from collections import Counter
print("status buckets:", dict(Counter(c[0] for c in res.values())))

# annotate
dead = []
for r in works:
    for c in r['claims']:
        code = res.get(c['url'], 'ERR')
        c['http'] = code
        c['verified'] = code.startswith('2')
        if not c['verified']:
            dead.append((code, c['url'][:100], r['work'], c['community']))

json.dump(works, open('data/crosscultural_ALL.json','w'), ensure_ascii=False, indent=1)
print(f"\nwrote data/crosscultural_ALL.json: {len(works)} works, {sum(len(r['claims']) for r in works)} claims")
print(f"\nunverified ({len(dead)}):")
for code, u, w, cm in dead[:25]:
    print(f"  [{code}] {cm} {w[:22]:<23} {u}")
