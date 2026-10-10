"""Fetch the pinned user-owned scenery exports, verifying parts and payloads."""
import concurrent.futures
import hashlib
import json
from pathlib import Path
import time
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
PIN = '16c06aee07c70eea5ed74e8420116998c27a4895'
BASE = f'https://raw.githubusercontent.com/gj94/transport-fever-3-mods/{PIN}/kerala_trackside_collection/'
OUT = ROOT / '.local/trackside-source'


def fetch(name, expected=None):
    target = OUT / name
    if target.exists() and (expected is None or hashlib.sha256(target.read_bytes()).hexdigest() == expected):
        return target
    target.parent.mkdir(parents=True, exist_ok=True)
    for attempt in range(4):
        try:
            with urllib.request.urlopen(BASE + name, timeout=90) as response:
                data = response.read()
            if expected and hashlib.sha256(data).hexdigest() != expected:
                raise ValueError('Checksum mismatch: ' + name)
            target.write_bytes(data)
            return target
        except Exception:
            if attempt == 3:
                raise
            time.sleep(attempt + 1)


def archive(entry):
    path = OUT / entry['file_name']
    if not path.exists() or hashlib.sha256(path.read_bytes()).hexdigest() != entry['sha256']:
        parts = [fetch(p['path'], p['sha256']) for p in entry['files']]
        data = b''.join(p.read_bytes() for p in parts)
        assert len(data) == entry['bytes']
        assert hashlib.sha256(data).hexdigest() == entry['sha256']
        path.write_bytes(data)
    with zipfile.ZipFile(path) as z:
        assert z.testzip() is None
        for member in z.infolist():
            target = (OUT / 'unpacked' / member.filename).resolve()
            assert target.is_relative_to((OUT / 'unpacked').resolve()), member.filename
        z.extractall(OUT / 'unpacked')
    print('VERIFIED', entry['file_name'], flush=True)


if __name__ == '__main__':
    index = json.loads(fetch('ASSET_INDEX.json').read_text())
    entries = json.loads(fetch('ARCHIVES.json').read_text())['archives']
    selected = [e for e in entries if e['delivery_role'] in ('portable_export', 'source')]
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        list(pool.map(archive, selected))
    for asset in index['assets']:
        source = asset['glb']
        path = OUT / 'unpacked' / source['path_in_archive']
        assert hashlib.sha256(path.read_bytes()).hexdigest() == source['sha256'], asset['asset_id']
    print('VERIFIED ALL', len(index['assets']), 'GLB payloads', flush=True)
