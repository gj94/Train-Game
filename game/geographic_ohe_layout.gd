extends RefCounted
## Immutable support layout shared by scenery workers. Wires remain per track;
## supports use one route-wide 55 m grid and the full cross-section of the yard.
const SPACING := 55.0
const CLEARANCE := 3.1 # includes the concrete footing, beyond the train envelope
const MAX_CANTILEVER_REACH := 6.5 # beyond this visual span, use a supported portal
const Clearance := preload("res://game/scenery_clearance.gd")
var graph: TrackGraph
var stations: Array
var bins := {}
var clearance
var shifted_rows := {}

func _init(world: RailWorld) -> void:
	graph=world.graph
	stations=world.stations
	clearance=Clearance.new(graph)
	for st in stations:
		if st.get("through_halt",true):continue
		var k:=roundi((st.s+60.0)/SPACING)
		if absf(k*SPACING-st.s-60.0)<5.0:shifted_rows[k]=k*SPACING+10.0
	for eid in graph.edges:
		var e: Dictionary=graph.edges[eid]
		for k in range(floori(e.chainage_start/250),floori(e.chainage_end/250)+1):
			if not bins.has(k):bins[k]=[]
			bins[k].append(eid)

func at_chainage(eid: String,chain: float,origin: Vector3) -> Vector3:
	var e: Dictionary=graph.edges[eid]
	return graph.position_relative(eid,(chain-e.chainage_start)/(e.chainage_end-e.chainage_start)*e.length,origin)

func row_chain(k: int) -> float:
	return shifted_rows.get(k,k*SPACING)

func attachment(eid: String,chain: float,k: int,origin: Vector3) -> Vector3:
	var e: Dictionary=graph.edges[eid]
	var along: float=(chain-e.chainage_start)/(e.chainage_end-e.chainage_start)*e.length
	var right:=graph.tangent(eid,along,1).cross(Vector3.UP).normalized()
	# All diverging/converging wires meet exactly over the shared rail node.
	# Otherwise alternate registration sides on the same route-wide row grid.
	var stagger:=0.0 if absf(chain-e.chainage_start)<.001 or absf(chain-e.chainage_end)<.001 else (.15 if k%2==0 else -.15)
	return at_chainage(eid,chain,origin)+Vector3.UP*6.1+right*stagger

func wire_spans(eid: String,start: float,end: float,origin: Vector3) -> Array:
	var e: Dictionary=graph.edges[eid]
	var lo: float=lerpf(e.chainage_start,e.chainage_end,start/e.length)
	var hi: float=lerpf(e.chainage_start,e.chainage_end,end/e.length)
	var result:=[]
	for k in range(floori(lo/SPACING)-1,ceili(hi/SPACING)+1):
		var row_a:=row_chain(k);var row_b:=row_chain(k+1)
		var a: float=maxf(row_a,e.chainage_start);var b: float=minf(row_b,e.chainage_end)
		if b<=a or hi<=a or lo>=b:continue
		var left:=attachment(eid,a,k,origin);var right:=attachment(eid,b,k+1,origin)
		# Clip the continuous span at chunk boundaries, retaining its original
		# phase. Chunk size must never alter the wire, sag or dropper positions.
		var cuts: Array[float]=[maxf(a,lo)]
		for j in range(1,8):
			var c:=lerpf(row_a,row_b,j/8.0)
			if c>cuts[0] and c<minf(b,hi):cuts.append(c)
		cuts.append(minf(b,hi))
		var contacts:=[];var messengers:=[];var droppers:=[]
		for c in cuts:
			var t: float=(c-a)/(b-a)
			var contact:=left.lerp(right,t)
			var upper:=contact+Vector3.UP*(1.0-.55*sin(PI*(c-row_a)/(row_b-row_a)))
			contacts.append(contact);messengers.append(upper)
		for j in [0,2,4,6]:
			var c:=lerpf(row_a,row_b,j/8.0)
			if c<maxf(a,lo) or c>=minf(b,hi):continue
			var contact:=left.lerp(right,(c-a)/(b-a))
			droppers.append([contact,contact+Vector3.UP*(1.0-.55*sin(PI*j/8.0))])
		result.append({start=cuts[0],end=cuts[-1],contacts=contacts,messengers=messengers,droppers=droppers})
	return result

func plans(eid: String,start: float,end: float,origin: Vector3) -> Array:
	var e: Dictionary=graph.edges[eid]
	var lo: float=lerpf(e.chainage_start,e.chainage_end,start/e.length)
	var hi: float=lerpf(e.chainage_start,e.chainage_end,end/e.length)
	var result:=[]
	for k in range(floori(lo/SPACING)-1,ceili(hi/SPACING)+1):
		var chain:=row_chain(k)
		if chain<lo or chain>=hi:continue
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
	var anchors: Array=[]
	var row:=roundi(chain/SPACING)
	for road in roads:
		var centre:=at_chainage(road,chain,origin)
		points.append(centre)
		anchors.append({road=road,centre=centre,contact=attachment(road,chain,row,origin)})
	points.sort_custom(func(a,b):return a.dot(right)<b.dot(right))
	anchors.sort_custom(func(a,b):return a.centre.dot(right)<b.centre.dot(right))
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
	var portal:=points.size()>2
	for i in posts.size():
		var delta: Vector3=anchors[0 if i==0 else -1].contact-posts[i]
		delta.y=0
		if delta.length()>MAX_CANTILEVER_REACH:portal=true
	if portal and posts.size()==1:
		# A single road beside a wide platform also needs a real second leg;
		# do not substitute an implausibly long unsupported station cantilever.
		var offset:=left
		var base:=p+right*offset
		for attempt in 80:
			if clearance.clear_point(base+origin,CLEARANCE):break
			offset-=.5;base=p+right*offset
		if not clearance.clear_point(base+origin,CLEARANCE):return {}
		posts.push_front(base)
	return {chainage=chain,points=points,anchors=anchors,posts=posts,right=right,forward=forward,
		portal=portal}

static func draw(batch,plan: Dictionary) -> void:
	var points: Array=plan.points
	var posts: Array=plan.posts
	var right: Vector3=plan.right
	var top: float=points.map(func(p):return p.y).max()+8.0
	if not plan.portal:
		for i in posts.size():
			var point: Vector3=plan.anchors[0 if i==0 else -1].contact
			var upper:=point+Vector3.UP
			var base: Vector3=posts[i]
			var side: float=signf((base-point).dot(right))
			_mast(batch,base,right,7.25)
			for height in [5.8,7.0]:
				var mount: Vector3=base+Vector3.UP*height
				batch.beam("metal",mount-right*.14,mount+right*.14,.09)
				var insulated:=mount.lerp(upper,.18)
				batch.beam("insulator",mount,insulated,.13)
				batch.beam("metal",insulated,upper,.065)
			var registration:=upper+right*side*.55-Vector3.UP*.45
			batch.beam("metal",upper,registration,.04)
			batch.beam("metal",registration,point,.035)
		return
	for base in posts:_mast(batch,base,right,top-base.y+.85)
	var a: Vector3=posts[0];a.y=top
	var b: Vector3=posts[-1];b.y=top
	for end in [a,b]:
		batch.beam("metal",end-plan.forward*.3,end+plan.forward*.3,.15)
		batch.beam("metal",end, end+Vector3.UP*.8,.12)
		batch.beam("metal",end+Vector3.UP*.8-plan.forward*.3,end+Vector3.UP*.8+plan.forward*.3,.15)
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
	for anchor in plan.anchors:
		var point: Vector3=anchor.contact
		var suspension:=point;suspension.y=top
		# Curving/fanning yard roads need a short outrigger to the cross beam.
		var foot:=a.lerp(b,clampf((suspension-a).dot(b-a)/a.distance_squared_to(b),0,1))
		batch.beam("metal",foot-plan.forward*.25,foot+plan.forward*.25,.08)
		batch.beam("metal",foot,suspension,.08)
		batch.beam("insulator",suspension,suspension-Vector3.UP*.6,.13)
		batch.beam("metal",suspension-Vector3.UP*.6,point+Vector3.UP,.04)
		batch.beam("metal",point+Vector3.UP,point,.035)

static func _mast(batch,base: Vector3,right: Vector3,height: float) -> void:
	batch.box("concrete",base+Vector3.UP*.15,Vector3(.7,.7,.75))
	for side in [-1,1]:
		batch.box("metal",base+right*side*.105+Vector3.UP*(height*.5),Vector3(.08,height,.12))
	for y in range(0,floori((height-.35)/.5)):
		batch.beam("metal",base-right*.105+Vector3.UP*(.35+y*.5),base+right*.105+Vector3.UP*(.85+y*.5),.035)
