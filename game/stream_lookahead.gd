extends RefCounted
## Presentation prediction follows the geographic alignment, never sets points or authority.
const STEP := 768.0

static func distance(speed: float, scale: int, maximum: float) -> float:
	if scale<1:return 0.0
	# Include a little acceleration lead when leaving a stop in fast-forward.
	# A one-tile lead at x1 can fill while waiting, before fast-forward is selected.
	return minf(maximum,STEP+maxf(speed,6.0)*float(scale)*7.0)

static func position(route: Dictionary, chainage: float) -> Vector3:
	var c: Array=route.chainage
	var low:=0;var high:=c.size()-1
	while high-low>1:
		var mid: int=(low+high)/2
		if float(c[mid])<=chainage:low=mid
		else:high=mid
	var a: Array=route.alignment[low];var b: Array=route.alignment[high]
	var blend:=clampf((chainage-float(c[low]))/maxf(.001,float(c[high])-float(c[low])),0,1)
	return Vector3(a[0],a[1],a[2]).lerp(Vector3(b[0],b[1],b[2]),blend)

static func points(route: Dictionary, edge: Dictionary, head_s: float, direction: int, ahead: float) -> Array[Vector3]:
	var result: Array[Vector3]=[]
	if ahead<=0 or not edge.has("chainage_start") or not route.has("chainage") or route.chainage.size()<2:return result
	var start:=lerpf(edge.chainage_start,edge.chainage_end,clampf(head_s/maxf(.001,edge.length),0,1))
	var travel:=signf(float(edge.chainage_end)-float(edge.chainage_start))*direction
	if travel==0:return result
	var last:=start
	for i in range(1,ceili(ahead/STEP)+1):
		var next:=clampf(start+travel*minf(i*STEP,ahead),float(route.chainage[0]),float(route.chainage[-1]))
		if absf(next-last)<1:break
		result.append(position(route,next));last=next
	return result
