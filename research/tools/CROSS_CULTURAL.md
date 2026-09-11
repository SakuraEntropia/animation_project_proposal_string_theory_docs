# CROSS-CULTURAL INTERPRETATION MODULE — collection protocol

## Hard constraints discovered by probing (2026-09)

`curl` returns JS shells for most modern sites. Only `web_fetch` yields real text.
Verified accessibility:

| Community | Representative source | web_fetch | Note |
|---|---|---|---|
| JA | hatena blog (*.hatenablog.com) | ✅ FULL TEXT | best accessible source |
| JA | manga-comic-netabare.com etc. | ✅ FULL TEXT | |
| JA | ja.wikipedia.org | ✅ | reference only |
| EN | en.wikipedia.org | ✅ FULL TEXT | reference only |
| EN | reddit.com / old.reddit.com | ❌ EMPTY SHELL | |
| EN | myanimelist.net forum | ❌ JS SHELL | |
| EN | anilist.co | ❌ JS SHELL | |
| EN | tvtropes.org | ❌ JS SHELL | |
| ZH | zhihu.com | ❌ 403 | |
| ZH | bilibili.com | ❌ JS SHELL | |
| ZH | zh.wikipedia.org | ✅ | reference only |
| ZH | pttweb.cc (Taiwan) | ⚠️ TITLE ONLY | truncated body |
| RU | 2ch.life | ❌ 403 CLOUDFLARE | |
| — | steamcommunity.com | ❌ DEAD | |
| — | filmboards (IMDb mirror) | ⚠️ UNTESTED | |

**Implication:** a genuine community-frequency count is NOT achievable from this
environment. What IS achievable: (a) actual retrieved interpretation claims with
citable URLs, (b) a platform-accessibility map that is itself a finding.

## Rule 1 — no fabrication
If a language community yields no retrievable source, report `NO RETRIEVABLE SOURCE`
for that language. Never infer community opinion.

## Rule 2 — every claim carries a URL
Every interpretation record must cite the exact URL it came from.
An uncited claim is discarded.

## Rule 3 — verbatim anchoring
Record a short verbatim fragment (<=15 words) from the source as the anchor,
so the claim can be checked.

## Rule 4 — no plot summary
Extract INTERPRETATIONS, not events.

## Record schema
```json
{"work":"","community":"EN|JA|ZH|KO|RU|other","platform":"",
 "url":"","verbatim":"","claim":"",
 "category":"D|E|C|B|A|F",
 "note":""}
```
category per task §10:
 A=author-confirmed  B=textually strong  C=community consensus
 D=plausible  E=weak theory  F=overinterpretation
Only assign A if a cited author statement is actually in the source.
Only assign C if the source itself describes the reading as widespread.

## Second output: accessibility map
```json
{"work":"","community":"","platform":"","reachable":true|false,"reason":""}
```
