"""Run after Godot's first import, before its final rescan (editor closed)."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'assets/models/ported'


def set_option(path, key, value):
    text = path.read_text()
    pattern = rf'^{re.escape(key)}=.*$'
    assert re.search(pattern, text, re.M), f'Missing import option {key}: {path}'
    path.write_text(re.sub(pattern, key + '=' + value, text, flags=re.M))


def main():
    sources = json.loads((ROOT / 'tools/coach_v02_sources.json').read_text())
    for source in sources['models']:
        key = source['id']
        path = ASSETS / (key + '.glb.import')
        # Source names are material IDs, never Godot name-suffix instructions.
        # In particular, LHB's glass ends in _alpha; stripping it breaks binding.
        for option, value in {
            'meshes/force_disable_compression': 'true',
            'nodes/use_name_suffixes': 'false',
            'nodes/use_node_type_suffixes': 'false',
        }.items():
            set_option(path, option, value)
        for texture in (ASSETS / (key + '_detail') / 'textures').glob('*.png.import'):
            set_option(texture, 'mipmaps/generate', 'true')
        print(key + ': source names, full-precision coordinates and marking mipmaps configured')


if __name__ == '__main__':
    main()
