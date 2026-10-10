"""Set baked RGB atlases to mipmapped BC7; preserve their full normal channels."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def atlas_paths():
    base = ROOT / 'assets/models/scenery/impostors'
    for kind in json.loads((base / 'buildings_catalog.json').read_text()):
        for channel in ('albedo', 'normal'):
            yield base / f'{kind}_{channel}.png'
    base = ROOT / 'assets/models/trackside/impostors'
    for kind in json.loads((base / 'catalog.json').read_text()):
        for channel in ('albedo', 'normal'):
            yield base / f'{kind.removeprefix("tf3_")}_{channel}.png'


def configure():
    count = 0
    for image in atlas_paths():
        target = Path(str(image) + '.import')
        # On a fresh bake, let the importer create its own UID/cache paths.
        content = target.read_text() if target.exists() else (
            '[remap]\nimporter="texture"\ntype="CompressedTexture2D"\n'
            '\n[params]\ncompress/mode=0\ncompress/high_quality=false\n'
            'compress/normal_map=0\nmipmaps/generate=false\n')
        for key, value in {'compress/mode': '2', 'compress/high_quality': 'true',
                           'compress/normal_map': '2', 'mipmaps/generate': 'true'}.items():
            content, changes = re.subn(rf'^{re.escape(key)}=.*$', f'{key}={value}',
                                       content, flags=re.MULTILINE)
            if not changes:
                content += f'{key}={value}\n'
        target.write_text(content, newline='\n')
        count += 1
    print(f'Configured {count} atlases; run Godot import to rebuild GPU textures.')


if __name__ == '__main__':
    configure()
