"""Prepare render-only road bridge/approach profiles; never edits railway inputs.

Run tools/export_scenery_context.gd first. Uses the same local Shapely/Numpy
dependencies as the existing map tools. Profiles are reconstruction from OSM,
SRTM and the rendered railway, not surveyed road elevations.
"""
from __future__ import annotations
import argparse
from collections import defaultdict, deque
import hashlib
import heapq
import json
import math
from pathlib import Path
import struct
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / ".local/kerala-route/python"))
from shapely.geometry import LineString, Point, Polygon, box, shape
from shapely.ops import unary_union
from shapely.strtree import STRtree
from shapely import affinity

GRADE = .075
STEP = 6.0
WIDTHS = dict(motorway=10, trunk=9, primary=8, secondary=6.5, tertiary=5.5,
              residential=4.5, service=3.6, footway=1.5, path=1, track=2.8)


def file_digest(path):
    data = path.read_bytes()
    if path.suffix != ".bin":
        data = data.replace(b"\r\n", b"\n")
    return hashlib.sha256(data).hexdigest()


def smoothstep(a, b, value):
    t = max(0, min(1, (value-a)/(b-a)))
    return t*t*(3-2*t)

def station_walkway(tags, geometry, station_tree):
    """Station civil models supply footbridges/stairs; don't add asphalt copies."""
    return (tags.get("highway") in ("footway", "path", "pedestrian")
            and tags.get("bridge", "no") != "no"
            and len(station_tree.query(geometry, predicate="intersects")) > 0)


class Ground:
    def __init__(self, context, source):
        self.source = source
        self.tiles = {}
        self.segments = context["ground_segments"]
        self.lines = [LineString([(s["a"][0], s["a"][2]), (s["b"][0], s["b"][2])]) for s in self.segments]
        self.tree = STRtree(self.lines)
        self.zones = context["zones"]
        self.zone_shapes = [Polygon(z["ring"]) for z in self.zones]
        self.zone_tree = STRtree(self.zone_shapes)
        self.station_bins = context["station_bins"]
        self.formation_bins = defaultdict(list)
        for region in context["formation_regions"]:
            for k in range(math.floor((region["start"]-280)/500), math.floor((region["end"]+280)/500)+1):
                self.formation_bins[k].append(region)
        self.bridges = context["bridges"]
        self.bridge_bins = defaultdict(list)
        for span in self.bridges:
            for k in range(math.floor(span["start"]/500), math.floor(span["end"]/500)+1):
                self.bridge_bins[k].append(span)

    def dem(self, x, z):
        key = (math.floor(x/4096), math.floor(z/4096))
        if key not in self.tiles:
            path = self.source / f"elevation/{key[0]}_{key[1]}.bin"
            self.tiles[key] = path.read_bytes() if path.exists() else b""
        data = self.tiles[key]
        if not data:
            return 0.0
        u, v = (x-key[0]*4096)/32, (z-key[1]*4096)/32
        ix, iz = min(127, max(0, math.floor(u))), min(127, max(0, math.floor(v)))
        def at(cx, cz):
            return struct.unpack_from("<h", data, 4+(cz*129+cx)*2)[0]*.1
        return (at(ix, iz)*(1-(u-ix))+at(ix+1, iz)*(u-ix))*(1-(v-iz)) + (at(ix, iz+1)*(1-(u-ix))+at(ix+1, iz+1)*(u-ix))*(v-iz)

    def nearest(self, p):
        i = int(self.tree.nearest(p))
        s, line = self.segments[i], self.lines[i]
        t = line.project(p, normalized=True) if line.length else 0
        return s, line.distance(p), s["a"][1]*(1-t)+s["b"][1]*t, s["s"]*(1-t)+s.get("end_s", s["s"]+line.length)*t

    def height(self, p):
        x, z = p.x, p.y
        h = self.dem(x, z)
        s, distance, rail_y, chain = self.nearest(p)
        width = 12 if s.get("depot") or s.get("yard") else self.formation_width(chain)
        bridge = not s.get("depot") and any(b["start"] <= chain <= b["end"] for b in self.bridge_bins[math.floor(chain/500)])
        h = formation_grade(h, rail_y, distance, width, bridge, s.get("depot") or s.get("yard"))
        best, target = 0, h
        for i in self.zone_tree.query(p.buffer(14)):
            zone = self.zones[int(i)]
            if zone["halt"]:
                continue
            dx, dz = x-zone["centre"][0], z-zone["centre"][1]
            along = abs(dx*zone["x"][0]+dz*zone["x"][1])-zone["extent"][0]/2
            across = dx*zone["z"][0]+dz*zone["z"][1]
            if across > zone["extent"][1]/2:
                continue
            weight = 1-smoothstep(0, 12, max(along, -across-zone["extent"][1]/2))
            if weight > best:
                best, target = weight, zone["height"]
        return h+(target-h)*best

    def formation_width(self, chain):
        width = 14.0
        for region in self.formation_bins[math.floor(chain/500)]:
            outside = max(region["start"]-chain, chain-region["end"])
            weight = 1-smoothstep(0, 280, outside)
            width = max(width, 14+(region["width"]-14)*weight)
        return width


def formation_grade(natural, rail_y, distance, width, bridge=False, yard=False):
    """Kept in parity with geographic_earthworks.gd; checked against route samples."""
    target = rail_y-.8 if bridge else rail_y-.15
    run = 58 if bridge or yard else max(18, min(90, 12+abs(natural-target)*2.5))
    graded = target+(natural-target)*smoothstep(width, width+run, distance)
    return min(natural, graded) if bridge else graded


def propagate(nodes, links, base, seeds, grade=GRADE):
    """Smallest connected-road uplift satisfying a bounded approach gradient."""
    heights = dict(seeds)
    queue = [(-h, node) for node, h in seeds.items()]
    heapq.heapify(queue)
    while queue:
        neg, node = heapq.heappop(queue)
        h = -neg
        if h < heights.get(node, -math.inf)-1e-7:
            continue
        for other, length in links[node]:
            candidate = h-grade*length
            if candidate > base[other]+.015 and candidate > heights.get(other, -math.inf)+1e-7:
                heights[other] = candidate
                heapq.heappush(queue, (-candidate, other))
    return heights


def water_edge_seeds(edges, base, heights, waters, water_heights, water_tree):
    """Keep an already raised deck's full width clear at its water-side ends.

    The centreline can leave a skewed bank before the outside deck corner does.
    Do not create a new bridge for an ordinary ground road's overlapping verge.
    """
    result = {}
    for edge in edges:
        a, b = edge["a"], edge["b"]
        ha, hb = heights.get(a, base[a]), heights.get(b, base[b])
        if not edge.get("structure") and max(ha-base[a], hb-base[b]) <= 1.2:
            continue
        ribbon = edge["line"].buffer(edge["width"]*.5+.25, cap_style=2)
        levels = [water_heights[int(i)] for i in water_tree.query(ribbon, predicate="intersects")
                  if water_heights[int(i)] is not None and ribbon.intersection(waters[int(i)]).area > .01]
        if not levels:
            continue
        floor = max(levels)+1.2
        for n, h in [(a, ha), (b, hb)]:
            if floor > h+.001:
                result[n] = max(result.get(n, -math.inf), floor)
    return result


def railway_edge_seeds(edges, base, heights, rail_tree, rail_heights, overhead_tree, overhead_heights):
    """Extend real railway flyovers across widened yards and their OHE spans."""
    result = {}
    for edge in edges:
        a, b = edge["a"], edge["b"]
        ha, hb = heights.get(a, base[a]), heights.get(b, base[b])
        if max(ha-base[a], hb-base[b]) <= .01:
            continue
        ribbon = edge["line"].buffer(edge["width"]*.5+3.0, cap_style=2)
        floor = -math.inf
        for ri in rail_tree.query(ribbon, predicate="intersects"):
            floor = max(floor, max(rail_heights[int(ri)])+10.0)
        for oi in overhead_tree.query(ribbon, predicate="intersects"):
            floor = max(floor, overhead_heights[int(oi)]+.85)
        for n, h in [(a, ha), (b, hb)]:
            if floor > h+.001:
                result[n] = max(result.get(n, -math.inf), floor)
    return result


def prepare(context, source, output, report_path, context_path):
    ground = Ground(context, source)
    rail_lines, rail_heights = [], []
    for road in context["rails"]:
        for a, b in zip(road["points"], road["points"][1:]):
            if math.hypot(b[0]-a[0], b[2]-a[2]) < .001:
                continue
            rail_lines.append(LineString([(a[0], a[2]), (b[0], b[2])]))
            rail_heights.append((a[1], b[1]))
    rail_tree = STRtree(rail_lines)
    overhead_lines = [LineString([o["a"],o["b"]]) for o in context.get("overhead",[])]
    overhead_heights = [o["height"] for o in context.get("overhead",[])]
    overhead_tree = STRtree(overhead_lines)
    features, waters, water_heights = [], [], []
    station_shapes = [Polygon(p["ring"]) for p in context["platforms"]] + ground.zone_shapes
    station_labels = [p["station"] for p in context["platforms"]] + [z["id"] for z in context["zones"]]
    station_tree = STRtree(station_shapes)
    station_walkways = defaultdict(set)
    digest = hashlib.sha256()
    inputs = {}
    paths = sorted((source/"tiles").glob("*.json"))
    for path in paths:
        tx, tz = map(int, path.stem.split("_"))
        # Include approach connections well outside the visible 220 m strip.
        if not len(ground.tree.query(box(tx*512-350, tz*512-350, (tx+1)*512+350, (tz+1)*512+350))):
            continue
        raw = path.read_bytes()
        digest.update(path.name.encode());digest.update(raw)
        inputs[path.relative_to(ROOT).as_posix()] = file_digest(path)
        tile = json.loads(raw)
        for feature in tile.get("features", []):
            kind = feature["kind"]
            if kind not in ("road", "water", "stream"):
                continue
            geometry = affinity.translate(shape(feature["geometry"]), tx*512, tz*512)
            if kind == "water":
                if not geometry.is_valid:
                    geometry = geometry.buffer(0)
                if not geometry.is_empty:
                    waters.append(geometry);water_heights.append(feature.get("water_height", 0))
            elif kind == "stream":
                tags = feature["tags"]
                if tags.get("tunnel", "no") != "no" or tags.get("covered") == "yes":
                    continue
                width = 4 if tags.get("waterway") == "river" else 1.2
                waters.append(geometry.buffer(width, cap_style=2))
                water_heights.append(None)
            else:
                tags = feature["tags"]
                if station_walkway(tags, geometry, station_tree):
                    for i in station_tree.query(geometry, predicate="intersects"):
                        station_walkways[feature["id"]].add(station_labels[int(i)])
                if (tags.get("highway") in ("proposed", "construction", "steps") or tags.get("tunnel", "no") != "no"
                        or tags.get("railway") == "platform" or float(tags.get("layer",0)) < 0):
                    continue
                for line in getattr(geometry, "geoms", [geometry]):
                    if line.length > .01:
                        features.append((feature["id"], tags, line))
    water_tree = STRtree(waters)
    nodes, node_ids, edges, seen_edges = [], {}, [], set()
    links = defaultdict(list)
    def node_id(x, z):
        key = (round(x, 3), round(z, 3))
        if key not in node_ids:
            node_ids[key] = len(nodes);nodes.append(key)
        return node_ids[key]
    for way, tags, line in features:
        if way in station_walkways:
            continue
        coords = list(line.coords)
        for a, b in zip(coords, coords[1:]):
            length = math.dist(a, b)
            count = max(1, math.ceil(length/STEP))
            # Keep original shared nodes, including clipped tile boundaries.
            ids = [node_id(a[0]+(b[0]-a[0])*i/count, a[1]+(b[1]-a[1])*i/count) for i in range(count+1)]
            for na, nb in zip(ids, ids[1:]):
                if na == nb:
                    continue
                key = (way, min(na, nb), max(na, nb))
                if key in seen_edges:
                    continue
                seen_edges.add(key)
                p, q = nodes[na], nodes[nb]
                segment = LineString([p, q])
                middle = segment.interpolate(.5, normalized=True)
                explicit = tags.get("bridge", "no") != "no"
                wet = [int(i) for i in water_tree.query(segment, predicate="intersects")]
                # A crossing needs the centreline over water, not just its
                # verge touching a bank or a wide road running parallel to it.
                wet = [i for i in wet if waters[i].intersection(segment).length > .05]
                levels = [water_heights[i] for i in wet if water_heights[i] is not None]
                edge = dict(way=way, a=na, b=nb, length=segment.length, explicit=explicit,
                            wet=bool(wet), water=max(levels) if levels else None,
                            width=WIDTHS.get(tags.get("highway"), 4), line=segment)
                edges.append(edge)
                links[na].append((nb, segment.length));links[nb].append((na, segment.length))
    print(f"Road network: {len(nodes)} vertices, {len(edges)} segments", flush=True)
    base = [ground.height(Point(p))+.07 for p in nodes]
    structural = defaultdict(list)
    for i, edge in enumerate(edges):
        if edge["explicit"] or edge["wet"]:
            structural[edge["a"]].append(i);structural[edge["b"]].append(i)
    used, seeds, rail_seeds, groups = set(), {}, {}, []
    for i, edge in enumerate(edges):
        if i in used or not (edge["explicit"] or edge["wet"]):
            continue
        queue, group = [i], []
        while queue:
            ei = queue.pop()
            if ei in used:
                continue
            used.add(ei);group.append(ei)
            e = edges[ei]
            for node in (e["a"], e["b"]):
                for other in structural[node]:
                    # Adjacent differently named OSM ways are one deck.
                    if other not in used:
                        queue.append(other)
        vertices = {n for ei in group for n in (edges[ei]["a"], edges[ei]["b"])}
        length = sum(edges[ei]["length"] for ei in group)
        explicit = any(edges[ei]["explicit"] for ei in group)
        # A long untagged submerged line is ambiguous. Do not invent a viaduct;
        # renderer will omit its wet fragments and the audit records it.
        if not explicit and length > 100:
            groups.append(dict(kind="unresolved_water",length=round(length,2),ways=sorted({edges[ei]["way"] for ei in group}),
                               centre=[round(sum(nodes[n][axis] for n in vertices)/len(vertices),3) for axis in (0,1)]))
            continue
        banks = [n for n in vertices if any(other not in vertices for other, _ in links[n])]
        floor = max(base[n] for n in (banks or vertices))+.35
        known_water = [edges[ei]["water"] for ei in group if edges[ei]["water"] is not None]
        if known_water:
            floor = max(floor, max(known_water)+1.2)
        if any(edges[ei]["wet"] and edges[ei]["water"] is None for ei in group):
            # Open stream geometry follows local ground rather than a surveyed
            # water datum. Leave air below the 0.4 m deck, not a submerged soffit.
            floor = max(floor, max(base[n] for n in vertices)+1.0)
        rail_crossings = set()
        if explicit:
            for ei in group:
                e = edges[ei]
                for ri in rail_tree.query(e["line"].buffer(e["width"]*.5+1), predicate="intersects"):
                    ri = int(ri);rail_crossings.add(ri)
                    # Clearance includes contact/messenger wires and deck soffit.
                    floor = max(floor, max(rail_heights[ri])+10.0)
                for oi in overhead_tree.query(e["line"].buffer(e["width"]*.5+3), predicate="intersects"):
                    floor = max(floor, overhead_heights[int(oi)]+.85)
        for node in vertices:
            seeds[node] = max(seeds.get(node, -math.inf), floor, base[node])
            if rail_crossings:
                rail_seeds[node] = max(rail_seeds.get(node, -math.inf), floor, base[node])
        for ei in group:
            edges[ei]["structure"] = True
        groups.append(dict(kind="rail_overbridge" if rail_crossings else ("mapped_bridge" if explicit else "inferred_culvert"),
                           length=round(length,2),height=round(floor,3),ways=sorted({edges[ei]["way"] for ei in group}),
                           centre=[round(sum(nodes[n][axis] for n in vertices)/len(vertices),3) for axis in (0,1)]))
    heights = propagate(nodes, links, base, seeds)
    rail_lifts = propagate(nodes, links, base, rail_seeds)
    water_edge_nodes = set()
    railway_edge_nodes = set()
    for iteration in range(16):
        extra = water_edge_seeds(edges, base, heights, waters, water_heights, water_tree)
        water_edge_nodes.update(extra)
        railway = railway_edge_seeds(edges, base, rail_lifts, rail_tree, rail_heights, overhead_tree, overhead_heights)
        railway_edge_nodes.update(railway)
        if not extra and not railway:
            break
        for node, height in railway.items():
            rail_seeds[node] = max(rail_seeds.get(node, -math.inf), height)
            extra[node] = max(extra.get(node, -math.inf), height)
        for node, height in extra.items():
            seeds[node] = max(seeds.get(node, -math.inf), height)
        heights = propagate(nodes, links, base, seeds)
        rail_lifts = propagate(nodes, links, base, rail_seeds)
    else:
        raise RuntimeError("Road clearance constraints did not settle in sixteen passes; no profile was written.")
    rows, biggest = [], 0
    for edge in edges:
        a, b = edge["a"], edge["b"]
        if a not in heights and b not in heights and not edge.get("structure"):
            continue
        ha, hb = max(base[a], heights.get(a, base[a])), max(base[b], heights.get(b, base[b]))
        biggest = max(biggest, ha-base[a], hb-base[b])
        rows.append([edge["way"], *nodes[a], round(ha,4), *nodes[b], round(hb,4), int(edge.get("structure", False))])
    for tx, tz in ground.tiles:
        path = source / f"elevation/{tx}_{tz}.bin"
        inputs[path.relative_to(ROOT).as_posix()] = file_digest(path) if path.exists() else None
    for name in ["tools/maps/road_surfaces.py", "tools/export_scenery_context.gd", "game/geographic_data.gd",
                 "game/station_precinct_plan.gd", "game/geographic_road_surface.gd", "game/geographic_road_profiles.gd",
                 "game/geographic_earthworks.gd", "game/geographic_ground_ribbon.gd"]:
        inputs[name] = file_digest(ROOT/name)
    result = dict(revision=1, source_sha256=digest.hexdigest(), grade=GRADE,
                  context_sha256=file_digest(context_path), inputs=inputs,
                  tile_names_sha256=hashlib.sha256("\n".join(p.name for p in paths).encode()).hexdigest(),
                  note="OSM/SRTM rendering reconstruction; no railway/simulation inputs changed",
                  station_pedestrian_ways=sorted(station_walkways),
                  segments=rows)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result,separators=(",",":"))+"\n", encoding="utf8")
    report = dict(vertices=len(nodes),edges=len(edges),profile_segments=len(rows),structures=groups,
                  water_edge_nodes=len(water_edge_nodes),railway_edge_nodes=len(railway_edge_nodes),
                  clearance_rounds=iteration,maximum_uplift=round(biggest,3),
                  file_bytes=output.stat().st_size,source_sha256=digest.hexdigest())
    report["omitted_station_walkways"] = [
        dict(way=way, stations=sorted(station_walkways[way])) for way in sorted(station_walkways)]
    report_path.write_text(json.dumps(report,indent=2)+"\n",encoding="utf8")
    print(json.dumps({k:v for k,v in report.items() if k!="structures"}),flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--context",type=Path,default=ROOT/".local/scenery-context.json")
    parser.add_argument("--source",type=Path,default=ROOT/"data/routes/kerala_coast")
    parser.add_argument("--output",type=Path,default=ROOT/"assets/models/scenery/road-surfaces.json")
    parser.add_argument("--report",type=Path,default=ROOT/".local/road-surfaces-report.json")
    args = parser.parse_args()
    prepare(json.loads(args.context.read_text(encoding="utf8")),args.source,args.output,args.report,args.context)
