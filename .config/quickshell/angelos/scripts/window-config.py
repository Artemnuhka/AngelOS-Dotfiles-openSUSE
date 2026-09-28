#!/usr/bin/env python3
"""Read or update niri layout preferences with a backup and validation."""
import json, re, subprocess, sys, tempfile, shutil, os
from pathlib import Path
home = Path.home()
path = home / '.config/niri/cfg/layout.kdl'
text = path.read_text()
def value(key, default):
    match = re.search(r'^\s*' + re.escape(key) + r'\s+([^\n/]+)', text, re.M)
    return match.group(1).strip().strip('"') if match else default
if len(sys.argv) == 1:
    print(json.dumps({'gaps': float(value('gaps', '16')), 'center': value('center-focused-column', 'never')}))
    sys.exit()
changes = json.loads(sys.argv[1])
if set(changes) - {'gaps','center'}:
    raise ValueError('Unknown layout preference')
new = text
for key, val in changes.items():
    if key == 'gaps':
        val = int(val)
        if not 0 <= val <= 64: raise ValueError('Gap out of range')
        node, result = 'gaps', str(val)
    else:
        if val not in ('never','always','on-overflow'): raise ValueError('Invalid centering')
        node, result = 'center-focused-column', json.dumps(val)
    pattern = r'^(\s*)' + node + r'\s+(?:"[^"]*"|[\d.]+)'
    if re.search(pattern, new, re.M):
        new = re.sub(pattern, lambda m: m[1]+node+' '+result, new, count=1, flags=re.M)
    else:
        new, count = re.subn(r'(\blayout\s*\{)', lambda m: m[1]+'\n        '+node+' '+result, new, count=1)
        if not count: raise ValueError('Layout block not found')
backup_root = home / '.local/state/angelos/backups'
backup_root.mkdir(parents=True, exist_ok=True)
backup = Path(tempfile.mkdtemp(prefix='window-layout-', dir=backup_root))
shutil.copy2(path, backup/path.name)
def write(content):
    fd, name = tempfile.mkstemp(prefix='.layout-', dir=path.parent)
    try:
        with os.fdopen(fd,'w') as f: f.write(content)
        os.chmod(name,path.stat().st_mode & 0o777)
        os.replace(name,path)
    finally:
        if os.path.exists(name): os.unlink(name)
write(new)
try:
    p = subprocess.run(['niri','validate'], capture_output=True, text=True)
    (backup/'validate.log').write_text(p.stdout+p.stderr)
    if p.returncode: raise RuntimeError(p.stderr)
except Exception:
    write(text)
    raise
print('Saved · '+str(backup))
