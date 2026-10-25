"""Independent pre-bake vs HEAD audit: preserve every existing geometry stream."""
import hashlib
import json
import struct
import subprocess
from pathlib import Path

from install_train_occlusion import preserved

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'assets/models/ported'


def decode(raw):
    length, = struct.unpack_from('<I', raw, 12)
    return json.loads(raw[20:20 + length])


def main():
    catalogue = json.loads((ASSETS / 'manifest.json').read_text())
    report = []
    for key, spec in catalogue.items():
        if not spec.get('detailed_materials') or not key.startswith(('wap7', 'lhb_', 'icf_', 'vb_')):
            continue
        relative = f'assets/models/ported/{key}.glb'
        if spec.get('passage_clearance_revision'):
            # These four interiors intentionally move a partition/handrail to
            # admit the player. Compare the lighting bake with that explicit
            # corrected geometry, not the historical blocked passage.
            references = json.loads((ROOT / 'art/performance/realism-2026-10-26/gangways/pre-occlusion/references.json').read_text(encoding='utf-8'))
            reference = references[key]
            assert spec['passage_clearance_revision'] == reference['revision'] == 1
            assert spec['source_sha256'] == reference['source_sha256']
            old = (ROOT / reference['path']).read_bytes()
            assert hashlib.sha256(old).hexdigest() == reference['sha256']
        else:
            old = subprocess.run(['git', '-c', 'safe.directory=D:/ClaudeWS/train-game', 'show', '2405060:' + relative], cwd=ROOT, check=True, capture_output=True).stdout
        new = (ROOT / relative).read_bytes()
        before, after = decode(old), decode(new)
        vertices = preserved(before, after)
        assert spec['output_sha256'] == hashlib.sha256(new).hexdigest()
        assert spec['occlusion']['samples'] == 24
        for dep in spec['dependencies']:
            raw = (ASSETS / dep['uri']).read_bytes()
            assert len(raw) == dep['byteLength']
            assert hashlib.sha256(raw).hexdigest() == dep['sha256']
        colour = (ASSETS / (key + '_detail') / 'occlusion.bin').read_bytes()
        assert len(colour) == vertices * 4
        assert min(colour[2::4]) == 255 and min(colour[3::4]) == 255
        assert min(colour[0::4]) < 200 and max(colour[0::4]) == 255
        report.append({'model': key, 'vertices': vertices, 'added_bytes': len(colour), 'triangles': spec['triangles'], 'preserved_original_streams': True})
        print('OCCLUSION_PASS', key, vertices, 'vertices', len(colour), 'bytes')
    out = ROOT / '.local/train-fidelity/geometry-audit.json'
    out.write_text(json.dumps({'models': report, 'total_bytes': sum(r['added_bytes'] for r in report), 'complete': True}, indent=2) + '\n', newline='\n')


if __name__ == '__main__':
    main()
