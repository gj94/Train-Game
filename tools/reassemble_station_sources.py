"""Reassemble only hash-verified station masters; never execute source scripts."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT/'.local/station-v02-source/south_indian_stations_v02'

def build():
    for code in ('ers', 'tvc', 'ncj'):
        parts = SOURCE/code/(code.upper()+'_full_station_v02.blend.parts')
        manifest = json.loads((parts/'manifest.json').read_text())
        data = bytearray()
        for part in manifest['parts']:
            path = (parts/part['filename']).resolve()
            assert path.parent == parts.resolve()
            block = path.read_bytes()
            assert len(block) == part['size']
            assert hashlib.sha256(block).hexdigest() == part['sha256']
            data.extend(block)
        assert len(data) == manifest['size']
        assert hashlib.sha256(data).hexdigest() == manifest['sha256']
        output = SOURCE/code/manifest['filename']
        assert output.resolve().parent == (SOURCE/code).resolve()
        if output.exists():
            assert output.read_bytes() == data
        else:
            output.write_bytes(data)
        print(code.upper(), len(data), manifest['sha256'])

if __name__ == '__main__':
    build()
