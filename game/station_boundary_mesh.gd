extends RefCounted
## Indian Railways-style precast concrete palisade, in metres.
static func section(batch,a: Vector3,b: Vector3) -> void:
	var direction: Vector3=(b-a);direction.y=0
	var length:=direction.length()
	if length<.15:return
	var along:=direction/length
	var normal:=along.cross(Vector3.UP)
	var basis:=Basis(along,Vector3.UP,normal)
	var post:=Color(.60,.54,.40,a.y)
	batch.box("station_boundary",a+Vector3.UP*1.04,Vector3(.24,2.08,.24),post,basis)
	for h in [.24,1.48]:
		batch.beam("station_boundary",a+Vector3.UP*h,b+Vector3.UP*h,.12,Color(.72,.72,.66,(a.y+b.y)*.5),.15)
	var count:=maxi(2,roundi(length/.22))
	for i in range(1,count):
		var p:=a.lerp(b,float(i)/count)
		var tone:=.94+.05*sin(p.x*17+p.z*31)
		var color:=Color(.77*tone,.77*tone,.70*tone,p.y)
		batch.box("station_boundary",p+Vector3.UP*.98,Vector3(.115,1.82,.085),color,basis)
		# Small bevelled head, rather than a row of square metal bars.
		var left:=p-along*.0575+Vector3.UP*1.89
		var right:=p+along*.0575+Vector3.UP*1.89
		for signum in [-1,1]:
			var shift: Vector3=normal*signum*.0425
			batch.quad("station_boundary",left+shift,right+shift,right-along*.023+Vector3.UP*.065+shift,left+along*.023+Vector3.UP*.065+shift,normal*signum,color)
		batch.box("station_boundary",p+Vector3.UP*1.95,Vector3(.069,.018,.085),color,basis)
