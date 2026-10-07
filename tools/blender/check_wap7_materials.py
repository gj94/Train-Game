"""Fast graph-coverage check; no geometry export. Run with autoexec disabled."""
import bpy
import json
import sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(Path(__file__).parent))
from wap7_materials import export_materials
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'.local/wap7-v02-source/wap7_photoreal_v02/WAP7_detail_v02.blend'),load_ui=False,use_scripts=False)
materials=[m for m in bpy.data.materials if not m.name.startswith('V02_STAGE')]
install='--install-assets' in sys.argv
result=export_materials(materials,ROOT/('assets/models/ported/wap7_detail/textures' if install else '.local/wap7-material-probe'))
(ROOT/'.local/wap7-material-probe.json').write_text(json.dumps(result))
if install:
    path=ROOT/'assets/models/ported/wap7_detail/materials.json'
    index=json.loads(path.read_text())
    index['materials']=[{k:v for k,v in m.items() if k!='code'} for m in result]
    path.write_text(json.dumps(index,indent=2)+'\n')
    (ROOT/'.local/wap7-materials.json').write_text(json.dumps(result,indent=2))
print('Compiled',len(result),'material graphs',flush=True)
