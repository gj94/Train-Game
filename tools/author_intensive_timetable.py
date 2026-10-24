"""Author an alternate operating day; never edit the standard timetable."""
import copy
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "art/timetables/kerala-coast-100-through-services.json"
TARGET = ROOT / "art/timetables/kerala-coast-intensive.json"
pack = json.loads(SOURCE.read_text(encoding="utf-8"))
pack["name"] = "Kerala Coast Intensive · 140 services"
original = {s["id"]: copy.deepcopy(s) for s in pack["services"]}


def retime(service, factor=1.0, local_dwell=None):
    previous_old = 0
    elapsed = 0
    prior_dwell = 0
    for index, stop in enumerate(service["stops"]):
        old_arrival = stop["minutes_from_origin"]
        old_dwell = stop["dwell_minutes"]
        if index:
            elapsed += prior_dwell + (old_arrival - previous_old) * factor
        stop["minutes_from_origin"] = round(elapsed, 2)
        if index and local_dwell is not None:
            stop["dwell_minutes"] = max(old_dwell, local_dwell)
        prior_dwell = stop["dwell_minutes"]
        previous_old = old_arrival + old_dwell


for service in pack["services"]:
    # Less padding for faster workings prevents an early express waiting eight
    # minutes while the stopping train it just passed is sent back in front.
    if service["id"] == "B002":
        retime(service, .83)
    if service["id"] == "K1":
        service["name"] = "Coastal All-Stations Passenger · Ernakulam to Nagercoil"
        # Passenger work, not an artificial equipment speed cap.
        retime(service, local_dwell=2.5)


def extras(template, first, last, departures, label, direction):
    for departure in departures:
        service = copy.deepcopy(original[template])
        stops = service["stops"]
        a = next(i for i, s in enumerate(stops) if s["block"].split("_P")[0] == first)
        b = next(i for i, s in enumerate(stops) if s["block"].split("_P")[0] == last)
        assert a < b
        service["stops"] = stops[a:b + 1]
        offset = service["stops"][0]["minutes_from_origin"]
        for s in service["stops"]:
            s["minutes_from_origin"] -= offset
        service["stops"][0]["dwell_minutes"] = 0
        # Origins use an existing compatible road; entry remains capacity gated.
        service["id"] = f"D{len(pack['services']):03d}"
        service["name"] = f"{label} {departure} · {first}–{last}"
        service["departure"] = departure
        service["scheduled_entry"] = True
        # Relief expresses share the parent express class. Giving every extra
        # a higher class starved B002 through a whole group of same-speed rakes.
        service["priority"] = original[template]["priority"]
        retime(service, .83)
        assert all(s["direction"] == direction for s in service["stops"])
        pack["services"].append(service)


# Limited-stop relief trains are grouped on the doubled middle section. The
# single-line ends retain the existing long-distance roster and crossing places.
# D105 leaves at12:55 to break the relief chain holding the12:45 Kollam regional
# after the balanced platform rebuild. Existing hundred-service bookings stay put.
extras("B002", "KYJ", "TVC",
       ["11:20", "11:35", "11:50", "12:05", "12:20", "12:55", "17:00", "18:00"],
       "Southern Relief Express", 1)
extras("B002", "QLN", "TVC",
       # An hourly later group avoids stacking four more expresses behind the
       # six KYJ reliefs: that sequence held delayed K1 at KZK for 45 minutes.
       ["16:10", "17:10", "18:10", "21:10", "19:10", "20:10"],
       "Capital Fast", 1)
extras("B002", "KYJ", "QLN",
       ["11:15", "11:30", "11:45", "15:10", "18:10", "20:10"],
       "Kayamkulam Fast", 1)
extras("B014", "TVC", "KYJ",
       ["08:25", "09:25", "10:25", "11:25", "14:25", "15:25", "17:25", "19:25"],
       "Backwater Relief Express", -1)
extras("B014", "TVC", "QLN",
       ["08:55", "09:55", "12:25", "13:25", "16:25", "18:25"],
       "Capital Fast", -1)
extras("B014", "QLN", "KYJ",
       ["08:20", "10:00", "11:40", "13:40", "15:40", "18:00"],
       "Kayamkulam Fast", -1)
assert len(pack["services"]) == 140
TARGET.write_text(json.dumps(pack, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"Wrote {len(pack['services'])} services to {TARGET}")
