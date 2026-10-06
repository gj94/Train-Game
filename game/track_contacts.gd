extends RefCounted
## Shared physical metadata for rendered gaps, point hardware and acoustic contacts.
## Existing game points have variable lengths; map the supplied assembly stations
## onto their actual toe, tongue heel and cast nose rather than invent another route.
const Layout := preload("res://game/rail_joint_layout.gd")
const RAIL_CENTRE := .874
var graph: TrackGraph
var junctions := {}
var contacts := {}
var _stations := {}

func _init(g: TrackGraph) -> void:
	graph=g
	_find_junctions()
	for eid in graph.edges:
		var list := []
		var k := 0
		var s := Layout.OFFSET
		while s<graph.edges[eid].length:
			if not in_assembly(eid,s): list.append(_contact(eid,s,k,0,"joint",1.0,"J%d"%k))
			s+=Layout.SPACING; k+=1
		for j in junctions.get(eid,[]):
			if j.frog<0: continue
			var at := from_node(eid,j.node,j.heel)
			var other := from_node(j.other,j.node,j.heel)
			var inner: float = signf((other.pos-at.pos).dot(at.right))*at.direction
			var rows := [[.01,-1,"joint",.5,"SRJ-L"],[.01,1,"joint",.5,"SRJ-R"],
				[lerpf(j.toe,j.heel,.469),inner,"switch",.12,"SW"],[j.heel-.5,-inner,"joint",.58,"ST"],
				[j.heel,inner,"joint",.62,"SH"],[lerpf(j.heel,j.nose,.54),-inner,"weld",.045,"LW-O"],
				[lerpf(j.heel,j.nose,.56),inner,"weld",.045,"LW-I"],[j.nose-1.698,inner,"joint",.68,"CT"],
				[j.nose,inner,"frog",1.05,"F"],[j.end-.025,inner,"joint",.68,"CH"],[j.end,-inner,"joint",.58,"EX"]]
			for i in rows.size():
				var row: Array=rows[i]
				var location := from_node(eid,j.node,row[0])
				var id: int=100000+graph.switches.keys().find(j.node)*100+i
				list.append(_contact(eid,location.s,id,row[1],row[2],row[3],j.node+"/"+row[4]))
		list.sort_custom(func(a,b): return a.s<b.s or (a.s==b.s and a.id<b.id))
		contacts[eid]=list
		var stations := PackedFloat64Array()
		for c in list: stations.append(c.s)
		_stations[eid]=stations

func _contact(eid: String,s: float,id: int,side: float,kind: String,strength: float,label: String) -> Dictionary:
	var right := graph.tangent(eid,s,1).cross(Vector3.UP)
	return {edge=eid,s=s,id=id,key=eid+":"+str(id),side=side,kind=kind,strength=strength,label=label,
		point=graph.position(eid,s)+right*side*RAIL_CENTRE,source=graph.position(eid,s)+right*side*.838+Vector3.UP*.3}

func from_node(eid: String,nid: String,d: float) -> Dictionary:
	var direction := 1 if graph.edges[eid].a==nid else -1
	var s := graph.entry_s(eid,direction)+direction*d
	var f := graph.tangent(eid,s,direction)
	return {pos=graph.position(eid,s),fwd=f,right=f.cross(Vector3.UP),s=s,direction=direction}

func _find_junctions() -> void:
	for nid in graph.switches:
		var sw: Dictionary=graph.switches[nid]
		var max_d := minf(280,minf(graph.edges[sw.normal].length,graph.edges[sw.reverse].length)*.48)
		var previous := 0.0
		var frog := -1.0
		var toe := -1.0
		for i in ceili(max_d*2):
			var d := i*.5
			var a := from_node(sw.normal,nid,d)
			var b := from_node(sw.reverse,nid,d)
			var separation: float=a.pos.distance_to(b.pos)
			if toe<0 and separation>=.065: toe=d
			if previous<2*RAIL_CENTRE and separation>=2*RAIL_CENTRE: frog=d
			if separation>5.5: max_d=d; break
			previous=separation
		for eid in [sw.normal,sw.reverse]:
			if not junctions.has(eid): junctions[eid]=[]
			var heel := maxf(1,toe)+9
			var nose := maxf(heel+4,frog+.45)
			junctions[eid].append({node=nid,other=sw.reverse if eid==sw.normal else sw.normal,primary=eid==sw.normal,
					extent=max_d,frog=frog,toe=maxf(1,toe),heel=heel,nose=nose,end=minf(graph.edges[eid].length*.49,nose+2.677) if frog>=0 else 0.0})

func in_assembly(eid: String,s: float) -> bool:
	for j in junctions.get(eid,[]):
		var distance: float=s if graph.edges[eid].a==j.node else graph.edges[eid].length-s
		if distance<=j.end: return true
	return false

func between(eid: String,a: float,b: float,include_start: bool=false) -> Array:
	var result := []
	var values: PackedFloat64Array=_stations[eid]
	var lo := values.bsearch(minf(a,b),true)
	var hi := values.bsearch(maxf(a,b),false)
	for i in range(lo,hi):
		var c: Dictionary=contacts[eid][i]
		if not include_start and c.s==a: continue
		result.append(c)
	if b<a: result.reverse()
	return result

func gaps(eid: String,start: float,end: float) -> Array:
	return between(eid,start,end,true).filter(func(c): return c.kind=="joint")

func at_gap(eid: String,s: float,side: float) -> bool:
	for c in between(eid,s-Layout.GAP*.499,s+Layout.GAP*.499,true):
		if c.kind=="joint" and (c.side==0 or c.side==side): return true
	return false

## Curvature is the turning angle between adjacent chord midpoints. It is zero
## on straight chords and bounded across polyline tessellation, not impulse-like
## at vertices. Edge endpoints use their last interior value, never another route.
func curvature(eid: String,s: float) -> float:
	var e: Dictionary=graph.edges[eid]
	if e.points.size()<3: return 0.0
	var segment := graph._segment_index(e,s)
	var left := maxi(1,segment)
	var right := mini(e.points.size()-2,segment+1)
	var a := _vertex_curvature(e,left)
	var b := _vertex_curvature(e,right)
	if left==right: return a
	return lerpf(a,b,clampf((s-e.cum[left])/(e.cum[right]-e.cum[left]),0,1))

func _vertex_curvature(e: Dictionary,i: int) -> float:
	var a: Vector3=e.points[i]-e.points[i-1]
	var b: Vector3=e.points[i+1]-e.points[i]
	var angle := wrapf(atan2(b.z,b.x)-atan2(a.z,a.x),-PI,PI)
	return angle/maxf(.01,(a.length()+b.length())*.5)
