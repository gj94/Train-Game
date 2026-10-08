"""Matching original seated character variants, built in background Blender only."""
import sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent))
from build_scenery import Geometry, save, MANIFEST, OUT
from scenery_people import person
import json
for name,colour,female in [('passenger_seated_man',(.20,.31,.37),False),('passenger_seated_phone',(.51,.46,.33),False),('passenger_seated_sari',(.36,.095,.16),True),('passenger_seated_blue',(.075,.24,.30),True)]:
    g=person(Geometry(name),female,colour,pose='seated',bag=False)
    # Carry the draped skirt over the knees; coordinates here are Blender Z-up.
    for i,(x,y,z) in enumerate(g.vertices):
        if female and z<.64:
            forward=.34*max(0,min(1,(.64-z)/.19))
            g.vertices[i]=(x,y+forward,z)
    save(g)
prior=json.loads((OUT/'manifest.json').read_text());prior.update(MANIFEST)
(OUT/'manifest.json').write_text(json.dumps(prior,indent=2)+'\n')
