"""Connect mapped road ends for rendering without changing the source map.

Simplified tile lines can omit a through-road vertex at a T-junction. Join an
endpoint within 2 cm, rather than treating every plan-view crossing as a road
junction. Layer changes connect only at shared bridge/approach endpoints.
"""
from collections import defaultdict
import math

from shapely.geometry import Point
from shapely.strtree import STRtree


def road_level(tags):
    return float(tags.get("layer", 0))


def build_road_network(features, step=6.0, tolerance=.02):
    lines = [row[2] for row in features]
    tree = STRtree(lines)
    parents, positions, keys, vertices = [], [], {}, []
    inserts = defaultdict(list)
    contacts = []

    def root(i):
        while parents[i] != i:
            parents[i] = parents[parents[i]]
            i = parents[i]
        return i

    def union(a, b):
        a, b = root(a), root(b)
        # Coordinate order makes the snapped position independent of tile order.
        if (positions[b], b) < (positions[a], a):
            a, b = b, a
        parents[b] = a

    for _, tags, line in features:
        ids = []
        for x, z in line.coords:
            p = (round(x, 3), round(z, 3))
            key = (road_level(tags), *p)
            if key not in keys:
                keys[key] = len(parents)
                parents.append(len(parents))
                positions.append(p)
            ids.append(keys[key])
        vertices.append(ids)

    for fi, (way, tags, line) in enumerate(features):
        coords = list(line.coords)
        for end in (0, len(coords)-1):
            p = Point(coords[end])
            for target in sorted(map(int, tree.query(p.buffer(tolerance)))):
                if target == fi:
                    continue
                other_way, other_tags, other_line = features[target]
                if p.distance(other_line) > tolerance:
                    continue
                other_coords = list(other_line.coords)
                distance = other_line.project(p)
                at_vertex = next((i for i, q in enumerate(other_coords)
                                  if math.dist(coords[end], q) <= tolerance), None)
                same_level = road_level(tags) == road_level(other_tags)
                if not same_level:
                    # A flyover is not connected to the road beneath it. A
                    # mapped bridge may, however, change layer at its ramp end.
                    bridge = any(t.get("bridge", "no") != "no" for t in (tags, other_tags))
                    if not bridge or at_vertex not in (0, len(other_coords)-1):
                        continue
                if at_vertex is not None:
                    union(vertices[fi][end], vertices[target][at_vertex])
                else:
                    # Do not join almost coincident parallel lines. A real
                    # T-junction approaches across the through-road direction.
                    before = other_line.interpolate(max(0, distance-.05))
                    after = other_line.interpolate(min(other_line.length, distance+.05))
                    tangent = (after.x-before.x, after.y-before.y)
                    neighbour = coords[1 if end == 0 else -2]
                    approach = (neighbour[0]-p.x, neighbour[1]-p.y)
                    cross = abs(tangent[0]*approach[1]-tangent[1]*approach[0])
                    denominator = math.hypot(*tangent)*math.hypot(*approach)
                    if denominator == 0 or cross/denominator < math.sin(math.radians(12)):
                        continue
                    inserts[target].append((distance, vertices[fi][end]))
                    contacts.append(dict(way=way, other=other_way, point=list(coords[end]),
                                         gap=p.distance(other_line), token=vertices[fi][end]))

    nodes, node_ids, edges, seen = [], {}, [], set()

    def vertex_node(token):
        token = root(token)
        if token not in node_ids:
            node_ids[token] = len(nodes)
            nodes.append(positions[token])
        return node_ids[token]

    for fi, (way, tags, line) in enumerate(features):
        coords = list(line.coords)
        along, distance = [(0.0, vertices[fi][0])], 0.0
        for i in range(1, len(coords)):
            distance += math.dist(coords[i-1], coords[i])
            along.append((distance, vertices[fi][i]))
        along.extend(inserts[fi])
        along.sort(key=lambda item: (item[0], positions[root(item[1])]))
        for (_, a), (_, b) in zip(along, along[1:]):
            na, nb = vertex_node(a), vertex_node(b)
            if na == nb:
                continue
            p, q = nodes[na], nodes[nb]
            count = max(1, math.ceil(math.dist(p, q)/step))
            ids = [na]
            # Subdivision points are private to this segment: coincident
            # samples at an un-noded crossing do not imply a junction.
            for i in range(1, count):
                ids.append(len(nodes))
                nodes.append(tuple(round(p[k]+(q[k]-p[k])*i/count, 3) for k in (0, 1)))
            ids.append(nb)
            for a_id, b_id in zip(ids, ids[1:]):
                key = (way, min(a_id, b_id), max(a_id, b_id))
                if key in seen or math.dist(nodes[a_id], nodes[b_id]) < .0001:
                    continue
                seen.add(key)
                edges.append((way, tags, a_id, b_id))
    for contact in contacts:
        contact['node'] = vertex_node(contact.pop('token'))
    return nodes, edges, contacts


def junction_aprons(nodes, edges, links, contacts, widths):
    """Small level road surfaces around a raised junction, including its edges.

    A matching centreline height alone leaves a step across the other road's
    width. Reach its half-width plus verge along every connected arm. Merge
    overlapping aprons before solving, so adjacent junctions settle together.
    """
    centres = {row['node'] for row in contacts}
    radius = {n: 3.0 for n in centres}
    for _, tags, a, b in edges:
        for n in (a,b):
            if n in radius:
                radius[n] = max(radius[n], widths.get(tags.get('highway'),4)*.5+1)
    regions, owners, parents = [],{},[]

    def root(i):
        while parents[i]!=i:
            parents[i]=parents[parents[i]];i=parents[i]
        return i

    for centre in sorted(centres):
        region, best, queue = set(),{centre:0.0},[(centre,0.0)]
        while queue:
            n,distance = queue.pop()
            region.add(n)
            if distance>=radius[centre]:
                continue
            for other,length in links[n]:
                next_distance=distance+length
                if next_distance<best.get(other,math.inf):
                    best[other]=next_distance;queue.append((other,next_distance))
        index=len(regions);regions.append(region);parents.append(index)
        for n in region:
            if n in owners:
                parents[root(index)]=root(owners[n])
            owners[n]=index
    merged=defaultdict(set)
    for i,region in enumerate(regions):
        merged[root(i)].update(region)
    return list(merged.values())


def junction_seeds(aprons, base, heights, profile_boundaries=()):
    seeds={}
    for region in aprons:
        if not any(n in heights or n in profile_boundaries for n in region):
            continue
        floor=max(max(base[n],heights.get(n,base[n])) for n in region)
        for n in region:
            if floor>max(base[n],heights.get(n,base[n]))+.0001:
                seeds[n]=floor
    return seeds
