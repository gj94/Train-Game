extends SceneTree
## Small reusable value-noise volume. Hardware interpolation replaces repeated
## per-pixel hash arithmetic; material scale, amplitudes and mip filtering remain.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var slices: Array[Image] = []
	for z in 64:
		var bytes := PackedByteArray()
		bytes.resize(64*64)
		for y in 64:
			for x in 64:
				var p := Vector3(fposmod(x*.1031,1.0),fposmod(y*.1031,1.0),fposmod(z*.1031,1.0))
				p += Vector3.ONE*p.dot(Vector3(p.y,p.z,p.x)+Vector3.ONE*33.33)
				bytes[y*64+x] = roundi(fposmod((p.x+p.y)*p.z,1.0)*255)
		slices.append(Image.create_from_data(64,64,false,Image.FORMAT_R8,bytes))
	var texture := ImageTexture3D.new()
	assert(texture.create(Image.FORMAT_R8,64,64,64,false,slices)==OK)
	assert(texture.get_data().size()==64, "Run this texture bake with the native renderer, not --headless")
	assert(ResourceSaver.save(texture,"res://assets/models/ported/wap7_detail/microfinish.res",ResourceSaver.FLAG_COMPRESS)==OK)
	print("WAP-7 shared microfinish volume: 64 cubed; generated successfully")
	quit()
