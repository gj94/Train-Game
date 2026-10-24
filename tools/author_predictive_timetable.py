"""Author separate Predictive V2 days; never overwrite the Classic service roster.

Relief departures are staggered across the morning/afternoon corridor instead
of launching a close KYJ platoon. Passing places remain dynamic; no hold sites,
extra slow-train dwell or equipment speed reductions are introduced here.
"""
import argparse
import copy
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]

# Existing services retain their actual stock, calls, run times and priorities.
# These are fictional operating-day departures, not a real published timetable.
DEPARTURES = {
    'D100':'11:20', 'D101':'11:55', 'D102':'12:30',
    'D103':'13:05', 'D104':'13:40', 'D105':'14:15',
    'D108':'12:20', 'D109':'13:00', 'D110':'13:40',
    'D111':'17:10', 'D112':'18:10', 'D113':'20:10',
    'D114':'11:15', 'D115':'13:20', 'D116':'15:10',
    'D117':'16:40', 'D118':'18:10', 'D119':'20:10',
}

def author(standard, intensive):
    regular=copy.deepcopy(standard)
    regular.update(name='Kerala Coast Predictive V2 · 100 services',dispatcher='predictive')
    busy=copy.deepcopy(intensive)
    busy.update(name='Kerala Coast Predictive V2 Intensive · 140 services',dispatcher='predictive')
    for service in busy['services']:
        departure=DEPARTURES.get(service['id'])
        if departure is None:continue
        old=service['departure'][:5]
        service['departure']=departure
        service['name']=service['name'].replace(old,departure)
    return regular,busy

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,default=ROOT/'art/timetables')
    args=parser.parse_args()
    standard=json.loads((ROOT/'art/timetables/kerala-coast-100-through-services.json').read_text(encoding='utf-8'))
    intensive=json.loads((ROOT/'art/timetables/kerala-coast-intensive.json').read_text(encoding='utf-8'))
    regular,busy=author(standard,intensive)
    args.output.mkdir(parents=True,exist_ok=True)
    for name,pack in [('kerala-coast-predictive.json',regular),('kerala-coast-intensive-v2.json',busy)]:
        (args.output/name).write_text(json.dumps(pack,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
        print(f'Wrote {len(pack["services"])} V2 services to {args.output/name}')
if __name__=='__main__':main()
