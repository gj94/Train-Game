"""Install the shared train visibility term without changing authored graphs.

Only detailed rolling stock is selected. The compiler carries the same extension
on subsequent full exports. No editor may be importing/running during this step.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INCLUDE = '#include "res://game/shaders/train_occlusion.gdshaderinc"'
TERM = ' AO = train_ambient_visibility(COLOR.rg);\n EMISSION = max(EMISSION, train_ceiling_emission(author_position.z));'


def extend(code):
    # Forward+ orients backface normals before the user's fragment code. The
    # old exporter flipped them a second time, lighting inner sheets from
    # below (especially obvious on the VB floor and coach ceiling panels).
    code = code.replace(' if (!FRONT_FACING) { NORMAL = -NORMAL; }\n', '')
    if INCLUDE in code:
        return code if 'train_ceiling_emission(author_position.z)' in code else code.replace(' AO = train_ambient_visibility(COLOR.rg);', TERM)
    code = code.replace('uniform mat4 author_from_mesh;', INCLUDE + '\nuniform mat4 author_from_mesh;', 1)
    end = code.rfind('}')
    assert 'void fragment()' in code and end > 0
    return code[:end] + TERM + '\n' + code[end:]


if __name__ == '__main__':
    catalogue = json.loads((ROOT / 'assets/models/ported/manifest.json').read_text())
    count = 0
    for key, spec in catalogue.items():
        if not spec.get('detailed_materials') or not key.startswith(('wap7', 'lhb_', 'icf_', 'vb_')):
            continue
        folder = ROOT / 'assets/models/ported' / (key + '_detail')
        index = json.loads((folder / 'materials.json').read_text())
        for name in {entry['shader'] for entry in index['materials']}:
            path = folder / 'shaders' / name
            path.write_text(extend(path.read_text()), newline='\n')
            count += 1
        staged = ROOT / '.local' / (key + '-materials.json')
        if staged.exists():
            entries = json.loads(staged.read_text())
            for entry in entries:
                entry['code'] = extend(entry['code'])
            staged.write_text(json.dumps(entries, indent=2) + '\n', newline='\n')
    print('Shared train occlusion installed in', count, 'authored shaders')
