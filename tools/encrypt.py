#!/usr/bin/env python3
"""
Build the locked web pages for the worldbuilding document set.

Each output is a SINGLE self-contained HTML file:
  - the plaintext is NEVER written to disk in the output directory
  - the ciphertext is embedded as base64
  - decryption happens client-side via WebCrypto (PBKDF2-SHA256 -> AES-256-GCM)
  - wrong password fails the GCM auth tag, so there is no oracle

Password resolution order (the passphrase is never committed):
  1. $ST_WORLDBUILDING_PASSWORD
  2. .repo-credentials  (gitignored, JSON: {"password": "..."})
"""
import base64, hashlib, json, os, secrets, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SRC = os.path.join(ROOT, '.build', 'out')
DST = os.path.join(ROOT, 'docs', 'worldbuilding')

ITERATIONS = 600_000
KEY_BITS = 256
SALT_BYTES = 16
IV_BYTES = 12


def resolve_password() -> str:
    pw = os.environ.get('ST_WORLDBUILDING_PASSWORD')
    if pw:
        return pw
    cred = os.path.join(ROOT, '.repo-credentials')
    if os.path.exists(cred):
        try:
            return json.load(open(cred))['password']
        except Exception as e:
            sys.exit(f"could not read {cred}: {e}")
    sys.exit(
        "no password available.\n"
        "  set ST_WORLDBUILDING_PASSWORD, or\n"
        "  create .repo-credentials with {\"password\": \"...\"}"
    )


def aesgcm_encrypt(password: str, plaintext: bytes):
    """PBKDF2-SHA256 -> AES-256-GCM, implemented with hashlib only (no deps).

    We use `cryptography` if present, else fall back to `openssl enc` for the
    AES-GCM step while still deriving the key with PBKDF2 here.
    """
    salt = secrets.token_bytes(SALT_BYTES)
    iv = secrets.token_bytes(IV_BYTES)
    key = hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), salt, ITERATIONS, KEY_BITS // 8)
    try:
        from cryptography.hazmat.primitives.ciphers.aead import AESGCM
        ct = AESGCM(key).encrypt(iv, plaintext, None)
    except ImportError:
        sys.exit("the `cryptography` package is required: pip install cryptography")
    return salt, iv, ct, key


PAGE = """<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>🔒 {title} · Re：LU</title>
<meta name="robots" content="noindex, nofollow">
<style>
  :root {{ --bg:#0d0f12; --fg:#e8e6e1; --dim:#8b8f96; --line:#23272d; --accent:#c9a227; }}
  * {{ box-sizing:border-box; }}
  body {{ margin:0; background:var(--bg); color:var(--fg);
         font:16px/1.75 -apple-system,"PingFang SC","Noto Sans CJK SC",system-ui,sans-serif; }}
  .wrap {{ max-width:820px; margin:0 auto; padding:56px 24px 120px; }}
  h1 {{ font-size:20px; font-weight:600; letter-spacing:.02em; margin:0 0 6px; }}
  .sub {{ color:var(--dim); font-size:13px; margin-bottom:32px; }}
  .lock {{ border:1px solid var(--line); border-radius:10px; padding:24px; background:#111418; }}
  label {{ display:block; font-size:13px; color:var(--dim); margin-bottom:8px; }}
  input {{ width:100%; padding:11px 13px; font-size:15px; color:var(--fg);
           background:#0a0c0f; border:1px solid var(--line); border-radius:7px; outline:none; }}
  input:focus {{ border-color:var(--accent); }}
  button {{ margin-top:14px; width:100%; padding:11px; font-size:15px; cursor:pointer;
            color:#0d0f12; background:var(--accent); border:0; border-radius:7px; font-weight:600; }}
  button:disabled {{ opacity:.5; cursor:progress; }}
  .msg {{ margin-top:14px; font-size:13px; min-height:20px; color:var(--dim); }}
  .msg.err {{ color:#e06c75; }}
  .meta {{ margin-top:26px; padding-top:18px; border-top:1px solid var(--line);
           font-size:12px; color:var(--dim); }}
  .meta code {{ color:#9aa4b2; }}
  #doc {{ display:none; }}
  #doc.on {{ display:block; }}
  .dochead {{ display:flex; justify-content:space-between; align-items:center;
              border-bottom:1px solid var(--line); padding-bottom:14px; margin-bottom:28px; }}
  .dochead .t {{ font-size:13px; color:var(--dim); }}
  .dochead button {{ width:auto; margin:0; padding:6px 12px; font-size:12px;
                     background:transparent; color:var(--dim); border:1px solid var(--line); }}
  pre {{ white-space:pre-wrap; word-wrap:break-word; font:14px/1.85 ui-monospace,
         SFMono-Regular,Menlo,monospace; color:#d7d3cc; }}
</style>
</head>
<body>
<div class="wrap">
  <h1>🔒 {title}</h1>
  <div class="sub"><b>Re：LU</b> · 官方标题　　开发代号：String Theory<br>
    本页内容已加密。输入密码以解密。<br>
    明文从未以未加密形式存储于本仓库。</div>

  <div id="gate" class="lock">
    <label for="pw">密码</label>
    <input id="pw" type="password" autocomplete="current-password" autofocus>
    <button id="go">解密</button>
    <div id="msg" class="msg"></div>
    <div class="meta">
      AES-256-GCM · PBKDF2-SHA256 · {iterations} iterations<br>
      SHA-256(ciphertext) = <code>{cthash}</code>
    </div>
  </div>

  <div id="doc">
    <div class="dochead">
      <span class="t">{title}</span>
      <button id="relock">重新锁定</button>
    </div>
    <pre id="body"></pre>
  </div>
</div>

<script id="payload" type="application/json">{payload}</script>
<script>
(function () {{
  const P = JSON.parse(document.getElementById('payload').textContent);
  const $ = (id) => document.getElementById(id);

  const b64 = (s) => {{
    const bin = atob(s), out = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
    return out;
  }};

  async function decrypt(pw) {{
    const enc = new TextEncoder();
    const base = await crypto.subtle.importKey('raw', enc.encode(pw), 'PBKDF2', false, ['deriveKey']);
    const key = await crypto.subtle.deriveKey(
      {{ name: 'PBKDF2', salt: b64(P.salt), iterations: P.iterations, hash: 'SHA-256' }},
      base, {{ name: 'AES-GCM', length: 256 }}, false, ['decrypt']);
    const pt = await crypto.subtle.decrypt(
      {{ name: 'AES-GCM', iv: b64(P.iv), tagLength: 128 }}, key, b64(P.ct));
    return new TextDecoder().decode(pt);
  }}

  async function attempt() {{
    const pw = $('pw').value;
    if (!pw) return;
    $('go').disabled = true;
    $('msg').className = 'msg';
    $('msg').textContent = '正在派生密钥…（约 1 秒）';
    try {{
      const text = await decrypt(pw);
      $('body').textContent = text;
      $('gate').style.display = 'none';
      $('doc').classList.add('on');
      document.title = {title_json};
      sessionStorage.setItem('st-pw', pw);
    }} catch (e) {{
      $('msg').className = 'msg err';
      $('msg').textContent = '密码错误。';
      $('pw').select();
    }} finally {{
      $('go').disabled = false;
    }}
  }}

  $('go').addEventListener('click', attempt);
  $('pw').addEventListener('keydown', (e) => {{ if (e.key === 'Enter') attempt(); }});
  $('relock').addEventListener('click', () => {{
    sessionStorage.removeItem('st-pw');
    $('body').textContent = '';
    $('pw').value = '';
    $('doc').classList.remove('on');
    $('gate').style.display = '';
    $('msg').textContent = '';
    document.title = {title_lock_json};
  }});

  // Auto-unlock within the same tab session (sessionStorage only, never cookies).
  const saved = sessionStorage.getItem('st-pw');
  if (saved) {{ $('pw').value = saved; attempt(); }}
}})();
</script>
</body>
</html>
"""


def build():
    password = resolve_password()
    os.makedirs(DST, exist_ok=True)
    files = sorted(f for f in os.listdir(SRC) if f.endswith('.md'))
    if not files:
        sys.exit(f"no source documents in {SRC}")

    index_entries = []
    for name in files:
        src = os.path.join(SRC, name)
        plaintext = open(src, 'rb').read()
        salt, iv, ct, _key = aesgcm_encrypt(password, plaintext)
        cthash = hashlib.sha256(ct).hexdigest()

        stem = name[:-3]
        out_name = stem.replace('_', '-') + '.html'
        title = stem.split('_', 1)[-1].replace('_', ' · ')

        payload = json.dumps({
            'salt': base64.b64encode(salt).decode(),
            'iv': base64.b64encode(iv).decode(),
            'ct': base64.b64encode(ct).decode(),
            'iterations': ITERATIONS,
            'sha256': cthash,
        }, separators=(',', ':'))

        html = PAGE.format(
            title=title,
            title_json=json.dumps(stem, ensure_ascii=False),
            title_lock_json=json.dumps('🔒 ' + title, ensure_ascii=False),
            iterations=ITERATIONS,
            cthash=cthash[:32] + '…',
            payload=payload,
        )
        open(os.path.join(DST, out_name), 'w').write(html)

        index_entries.append((stem, out_name, title, len(plaintext), len(ct), cthash))
        print(f"  {name:34s} {len(plaintext):7d} B plain -> {len(ct):7d} B ct  -> {out_name}")

    # index page (no secrets: titles only, all pages need the password anyway)
    rows = '\n'.join(
        f'      <li><a href="{o}">{t}</a><span class="n">{p:,} B 明文 · {c:,} B 密文</span></li>'
        for _, o, t, p, c, _ in index_entries)
    idx = f"""<!DOCTYPE html>
<html lang="zh-CN"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Re：LU · 设定文档（加密）</title>
<meta name="robots" content="noindex, nofollow">
<style>
 body {{ margin:0; background:#0d0f12; color:#e8e6e1;
        font:16px/1.8 -apple-system,"PingFang SC","Noto Sans CJK SC",system-ui,sans-serif; }}
 .wrap {{ max-width:760px; margin:0 auto; padding:64px 24px 120px; }}
 h1 {{ font-size:22px; font-weight:600; margin:0 0 8px; }}
 .sub {{ color:#8b8f96; font-size:13px; margin-bottom:36px; }}
 .namestat {{ margin:14px 0 36px; padding:14px 16px; border:1px solid #c9a22755;
              border-radius:8px; background:#141310; color:#cfc7ae; font-size:13px;
              line-height:1.7; }}
 .namestat b {{ color:#c9a227; }}
 ul {{ list-style:none; padding:0; margin:0; }}
 li {{ display:flex; justify-content:space-between; align-items:baseline; gap:16px;
       padding:14px 0; border-bottom:1px solid #23272d; }}
 a {{ color:#c9a227; text-decoration:none; font-size:15px; }}
 a:hover {{ text-decoration:underline; }}
 .n {{ color:#6f747c; font-size:12px; white-space:nowrap; }}
 .note {{ margin-top:36px; padding-top:20px; border-top:1px solid #23272d;
          color:#8b8f96; font-size:13px; }}
</style></head><body><div class="wrap">
  <h1>Re：LU · 设定文档</h1>
  <div class="namestat">
    <b>官方标题：Re：LU</b>　·　主题歌：Zona Pellucida　·　开发代号：String Theory<br>
    本目录的文档为<b>开发期材料</b>，题名沿用当时的代号 String Theory；
    依命名规则<b>不回改历史文档</b>。
  </div>
  <div class="sub">全部页面为 AES-256-GCM 客户端加密。明文不在本仓库中。</div>
  <ul>
{rows}
  </ul>
  <div class="note">
    每个页面是独立的单文件 HTML，可直接离线打开。<br>
    密码错误会失败于 GCM 认证标签，不会泄露任何信息。
  </div>
</div></body></html>
"""
    open(os.path.join(DST, 'index.html'), 'w').write(idx)
    print(f"\n  index.html written ({len(index_entries)} documents)")
    print(f"  output: {DST}")


if __name__ == '__main__':
    build()
