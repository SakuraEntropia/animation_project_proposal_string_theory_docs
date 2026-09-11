# RECORD SCHEMA v1 — locked

Every work gets EXACTLY these fields. No free-form essays.

```json
{
  "title": "",
  "medium": "anime|anime_film|manga|film|novel|game|vn|short",
  "year": 0,
  "wbid": 0,        // worldbuilding density 0-10
  "fsid": 0,        // foreshadowing 0-10
  "rwid": 0,        // rewatch/reread value 0-10
  "symd": 0,        // symbolism density 0-10
  "comm": "L|M|H",  // community discussion volume
  "conf": "A|B|C",  // A=high confidence in my knowledge, B=moderate, C=thin/uncertain
  "src": "K" | "K+W",  // K = model knowledge, K+W = knowledge + web verification
  "fs": ["pat_id", "pat_id", "pat_id"],        // top 3 foreshadowing mechanisms (pattern ids)
  "sym": ["sym_id", "sym_id", "pat_id"],        // top 3 symbolism types
  "wb": ["pat_id", "pat_id", "pat_id"],         // top 3 worldbuilding techniques
  "lesson": ""      // ONE sentence: most valuable lesson for a project about
                    //   universe-scale entropy + a civilization with a broken tech tree
}
```

Rules:
- `fs`, `sym`, `wb` MUST use ids from `taxonomy.md`. Never invent ids.
- If you are NOT confident about a work, still emit the record but set `conf:"C"` and leave
  `fs`/`sym`/`wb` as `[]`. A missing record is better than a fabricated one.
- `lesson` is at most 25 words.
- Do NOT write plot summaries. Ever.
