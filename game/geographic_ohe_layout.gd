extends RefCounted
## Immutable support layout shared by scenery workers. Wires remain per track;
## supports use one route-wide 55 m grid and the full cross-section of the yard.
const SPACING := 55.0
const CLEARANCE := 3.1 # includes the concrete footing, beyond the train envelope
const Clearance := preload("res://game/scenery_clearance.gd")
var graph: TrackGraph
var stations: Array
var bins := {}
var clearance

func _init(world: RailWorld) -> void:
	graph=world.graph
	stations=world.stations
	clearance=Clearance.new(graph)
	for eid in graph.edges:
		var e: Dictionary=graph.edges[eid]
		for k in range(floori(e.chainage_start/250),floori(e.chainage_end/250)+1):
			if not bins.has(k):bins[k]=[]
			bins[k].append(eid)

func at_chainage(eid: String,chain: float,origin: Vector3) -> Vector3:
	var e: Dictionary=graph.edges[eid]
	return graph.position_relative(eid,(chain-e.chainage_start)/(e.chainage_end-e.chainage_start)*e.length,origin)

func plans(eid: String,start: float,end: float,origin: Vector3) -> Array:
	var e: Dictionary=graph.edges[eid]
	var lo: float=lerpf(e.chainage_start,e.chainage_end,start/e.length)
	var hi: float=lerpf(e.chainage_start,e.chainage_end,end/e.length)
	var result:=[]
	for k in range(ceili(lo/SPACING),ceili(hi/SPACING)):
		var chain:=k*SPACING
		for st in stations:
			if not st.get("through_halt",true) and absf(chain-st.s-60)<5:chain+=10
		var plan:=section(eid,chain,origin)
		if not plan.is_empty():result.append(plan)
	return result

func section(eid: String,chain: float,origin: Vector3) -> Dictionary:
	var roads: Array=[]
	for candidate: String in bins.get(floori(chain/250),[]):
		var e: Dictionary=graph.edges[candidate]
		if chain>=e.chainage_start and chain<e.chainage_end:roads.append(candidate)
	roads.sort()
	if roads.is_empty() or roads[0]!=eid:return {} # exactly one owner, including chunk boundaries
	var p:=at_chainage(eid,chain,origin)
	var e: Dictionary=graph.edges[eid]
	var along: float=(chain-e.chainage_start)/(e.chainage_end-e.chainage_start)*e.length
	var forward:=graph.tangent(eid,along,1)
	forward.y=0;forward=forward.normalized()
	var right:=forward.cross(Vector3.UP)
	var points: Array=[]
	for road in roads:points.append(at_chainage(road,chain,origin))
	points.sort_custom(func(a,b):return a.dot(right)<b.dot(right))
	var left: float=(points[0]-p).dot(right)-3.6
	var rightmost: float=(points[-1]-p).dot(right)+3.6
	# Place yard foundations outside the passenger platforms as well.
	for st in stations:
		if absf(chain-st.s)>330:continue
		for road in st.platform_tracks:
			var detail: Dictionary=st.platform_details[road]
			if detail.platform_width<=0:continue
			var offset: float=(at_chainage(road,chain,origin)-p).dot(right)
			var far: float=offset+detail.platform_side*(2.02+detail.platform_width+.9)
			left=minf(left,far);rightmost=maxf(rightmost,far)
	var posts: Array=[]
	for side in [-1,1]:
		if points.size()==1 and side==-1:continue
		var offset: float=left if side==-1 else rightmost
		var base:=p+right*offset
		# Check the actual curved/switch segments, not just nominal track spacing.
		for attempt in 80:
			if clearance.clear_point(base+origin,CLEARANCE):break
			offset+=side*.5;base=p+right*offset
		if not clearance.clear_point(base+origin,CLEARANCE):return {}
		posts.append(base)
	return {chainage=chain,points=points,posts=posts,right=right,forward=forward,
		portal=points.size()>2}

static func draw(batch,plan: Dictionary) -> void:
	var points: Array=plan.points
	var posts: Array=plan.posts
	var right: Vector3=plan.right
	var top: float=points.map(func(p):return p.y).max()+8.0
	if not plan.portal:
		for i in posts.size():
			var point: Vector3=points[0 if i==0 else -1]
			var base: Vector3=posts[i]
			var side: float=signf((base-point).dot(right))
			_mast(batch,base,right,7.25)
			batch.beam("metal",base+Vector3.UP*5.8,point+Vector3.UP*6.3,.08)
			batch.beam("metal",base+Vector3.UP*7,point+Vector3.UP*6.3,.055)
			batch.beam("insulator",base-right*side*.45+Vector3.UP*6.93,base-right*side*.9+Vector3.UP*6.78,.13)
			batch.beam("metal",point-right*.3+Vector3.UP*6.1,point+right*.3+Vector3.UP*6.1,.035)
			batch.beam("metal",point+Vector3.UP*6.1,point+Vector3.UP*6.3,.035)
		return
	for base in posts:_mast(batch,base,right,top-base.y+.85)
	var a: Vector3=posts[0];a.y=top
	var b: Vector3=posts[-1];b.y=top
	for offset in [-.25,.25]:
		var depth: Vector3=plan.forward*offset
		batch.beam("metal",a+depth,b+depth,.12)
		batch.beam("metal",a+depth+Vector3.UP*.8,b+depth+Vector3.UP*.8,.12)
		var bays:=ceili(a.distance_to(b)/2)
		for j in bays:
			var lo:=a.lerp(b,float(j)/bays)+depth
			var hi:=a.lerp(b,float(j+1)/bays)+depth
			batch.beam("metal",lo,hi+Vector3.UP*.8,.06)
			batch.beam("metal",lo+Vector3.UP*.8,hi,.06)
	for point in points:
		var suspension: Vector3=point;suspension.y=top
		batch.beam("insulator",suspension,suspension-Vector3.UP*.6,.13)
		batch.beam("metal",suspension-Vector3.UP*.6,point+Vector3.UP*6.1,.04)
		batch.beam("metal",point-right*.3+Vector3.UP*6.1,point+right*.3+Vector3.UP*6.1,.035)

static func _mast(batch,base: Vector3,right: Vector3,height: float) -> void:
	batch.box("concrete",base+Vector3.UP*.15,Vector3(.7,.7,.75))
	for side in [-1,1]:
		batch.box("metal",base+right*side*.105+Vector3.UP*(height*.5),Vector3(.08,height,.12))
	for y in range(0,floori((height-.35)/.5)):
		batch.beam("metal",base-right*.105+Vector3.UP*(.35+y*.5),base+right*.105+Vector3.UP*(.85+y*.5),.035)
