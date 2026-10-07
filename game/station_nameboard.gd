extends RefCounted
## Physical, double-sided lettering with measured widths and script shaping.
const WIDTH := 5.6
const HEIGHT := 1.5
static var _font: SystemFont
static func font() -> SystemFont:
	if _font == null:
		_font=SystemFont.new()
		_font.font_weight=700
		_font.font_names=PackedStringArray(["Nirmala UI","Noto Sans Malayalam","Noto Sans Tamil","Arial"])
	return _font
static func lines(station: Dictionary) -> Array:
	var local: String=station.get("board_local_name",station.get("local_name",""))
	var english: String=station.get("board_name",station.name).to_upper()
	var hindi: String=station.get("board_hindi","")
	var result: Array=[]
	if not local.is_empty():result.append(local)
	if not hindi.is_empty():result.append(hindi)
	result.append(english)
	return result
static func add(root: Node3D,station: Dictionary,position: Vector3,basis: Basis) -> void:
	var rows:=lines(station)
	for face in [1,-1]:
		var facing:=basis if face==1 else basis*Basis(Vector3.UP,PI)
		for index in rows.size():
			var label:=Label3D.new()
			label.name="StationName_"+str(face)+"_"+str(index)
			label.font=font();label.font_size=96;label.text=rows[index]
			var measured:=maxf(1,font().get_string_size(rows[index],HORIZONTAL_ALIGNMENT_LEFT,-1,96).x)
			var row_height:=.40 if rows.size()==3 else .53
			label.pixel_size=minf(row_height/font().get_height(96),(WIDTH-.42)/measured)
			label.modulate=Color(.035,.035,.025);label.outline_size=0
			label.no_depth_test=false;label.double_sided=false
			var step:=.44 if rows.size()==3 else .58
			label.position=position+basis.z*face*.061+Vector3.UP*((rows.size()-1)*step*.5-index*step)
			label.basis=facing;label.visibility_range_end=330
			root.add_child(label)
