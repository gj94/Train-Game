extends RefCounted
## Streets and original architecture follow the deterministic land-use plan.
const Geometry:=preload("res://game/scenery_geometry.gd")
const SHOPS:=["KAVERI STORES","SARAVANA TEA","RAJA CYCLES","AMMAN TEXTILES","SRI RAM MEDICALS","DEVI ELECTRICALS","GOPAL PROVISIONS","KUMAR HARDWARE","ANNAPOORNA HOTEL","SELVI TAILORS"]
const TAMIL:=["காவேரி மளிகை","சரவணா தேநீர்","ராஜா சைக்கிள்ஸ்","அம்மன் ஜவுளி","மருந்தகம்","மின்சாதனங்கள்","மளிகைக் கடை","வன்பொருள் கடை","அன்னபூர்ணா உணவகம்","செல்வி தையலகம்"]
var view
var plan
var library
var geometry
var font:=SystemFont.new()
var materials:={}
func build(world_view,layout,assets) -> void:
	view=world_view
	plan=layout
	library=assets
	geometry=Geometry.new(view)
	font.font_names=PackedStringArray(["Nirmala UI","Arial"])
	font.font_weight=650
	_materials()
	for plot in plan.surfaces: geometry.plane(plot.rect,.008,materials.get(plot.kind,materials.yard))
	for road in plan.roads: _street(road)
	for bay in plan.bus_bays: _bus_bay(bay)
	for index in plan.buildings.size():
		var item: Dictionary=plan.buildings[index]
		library.place(item.kind,item.position,item.angle)
		_plot_detail(item,index)
	for item in plan.props:
		library.place(item.kind,item.position,item.angle)
		if item.kind=="bus_shelter": _text("BUS STOP • பேருந்து நிறுத்தம்",item.position+Basis(Vector3.UP,item.angle)*Vector3(0,2.83,-1.585),.19,Color(.86,.82,.61),item.angle+PI)
		elif item.kind=="produce_cart": _text("FRESH PRODUCE",item.position+Basis(Vector3.UP,item.angle)*Vector3(0,2.18,-.85),.13,Color(.86,.82,.61),item.angle+PI)
	_wires()
	for item in plan.fields: _field(item)
	geometry.flush()
func _materials() -> void:
	materials.yard=view.pbr("red_laterite_soil_stones",3.5,Color(.76,.73,.63))
	materials.concrete=view.pbr("brushed_concrete",2.0,Color(.63,.62,.56))
	materials.wall=view.pbr("plastered_wall",2.0,Color(.71,.67,.54))
	materials.brick=view.pbr("red_brick_plaster_patch_02",2.5,Color(.64,.56,.43))
	materials.paving=_ground_material("pavement_06",3.2,Vector3(.82,.79,.69),false)
	materials.asphalt=_ground_material("aerial_asphalt_01",8.0,Vector3(.51,.53,.52),true)
	materials.lane=_ground_material("red_laterite_soil_stones",4.0,Vector3(.69,.64,.50),false)
	materials.paint=view.mat(Color(.69,.68,.55))
	materials.wire=view.mat(Color(.055,.065,.061))
	materials.water=ShaderMaterial.new()
	materials.water.shader=load("res://game/shaders/paddy_water.gdshader")
	materials.water.set_shader_parameter("ripple_strength",.22)
	materials.water.set_shader_parameter("water_roughness",.37)
	for stage in 5:
		var field:=ShaderMaterial.new()
		field.shader=load("res://game/shaders/scenery_field.gdshader")
		field.set_shader_parameter("soil_albedo",view.ph_tex("red_laterite_soil_stones","diff"))
		field.set_shader_parameter("crop_albedo",view.ph_tex("leafy_grass","diff"))
		field.set_shader_parameter("stage",stage)
		materials["field%d"%stage]=field
func _ground_material(asset: String,metres: float,tint: Vector3,road: bool) -> Material:
	var mat:=ShaderMaterial.new()
	mat.shader=load("res://game/shaders/scenery_road.gdshader")
	for pair in [["surface_albedo","diff"],["surface_normal","nor_gl"],["surface_rough","rough"]]:
		mat.set_shader_parameter(pair[0],view.ph_tex(asset,pair[1]))
	mat.set_shader_parameter("metres",metres)
	mat.set_shader_parameter("tint",tint)
	mat.set_shader_parameter("road_surface",road)
	return mat


func _street(road: Dictionary) -> void:
	var a: Vector3=road.a
	var b: Vector3=road.b
	var d: Vector3=(b-a).normalized()
	var side:=d.cross(Vector3.UP)
	var width: float=road.width
	geometry.road(a-Vector3.UP*.085,b-Vector3.UP*.085,width+3.2,materials.yard)
	geometry.road(a,b,width,materials[road.kind])
	if width<5.7: return
	for sign in [-1,1]:
		var offset: float=sign*(width*.5+1.05)
		for section: Vector2 in plan.curb_sections(road,offset,.8):
			geometry.road(a+d*section.x+side*offset+Vector3.UP*.07,a+d*section.y+side*offset+Vector3.UP*.07,1.6,materials.paving)
		offset=sign*(width*.5+.16)
		for section: Vector2 in plan.curb_sections(road,offset,.12):
			geometry.line(a+d*section.x+side*offset+Vector3.UP*.025,a+d*section.y+side*offset+Vector3.UP*.025,.23,.21,materials.concrete)
		offset=sign*(width*.5+2.0)
		for section: Vector2 in plan.curb_sections(road,offset,.18):
			geometry.road(a+d*section.x+side*offset-Vector3.UP*.06,a+d*section.y+side*offset-Vector3.UP*.06,.34,materials.wire)
			for distance in range(ceili(section.x)+2,floori(section.y)-1,9):
				geometry.box(Vector3(.85,.10,.55),a+d*distance+side*offset+Vector3.UP*.075,materials.concrete,Vector3(0,atan2(d.x,d.z),0))
	if width>=7:
		for distance in range(6,int(a.distance_to(b))-6,10):
			var p:=a+d*distance
			var crosses:=false
			for other in plan.roads:
				if absf((other.b-other.a).normalized().dot(d))<.5 and other.rect.grow(2).has_point(Vector2(p.x,p.z)): crosses=true; break
			if not crosses: geometry.road(p+Vector3.UP*.016,p+d*4+Vector3.UP*.016,.12,materials.paint)
func _bus_bay(bay: Dictionary) -> void:
	var rect: Rect2=bay.rect
	var side: float=bay.side
	var z: float=bay.street_z+side*8.8
	geometry.plane(rect,.105,materials.asphalt)
	var a:=Vector3(rect.position.x,.17,z+side*1.05)
	var b:=Vector3(rect.end.x,.17,z+side*1.05)
	geometry.road(a,b,1.6,materials.paving)
	geometry.line(Vector3(a.x,.125,z),Vector3(b.x,.125,z),.23,.21,materials.concrete)
	for x in [a.x,b.x]:
		geometry.line(Vector3(x,.125,bay.street_z+side*4.16),Vector3(x,.125,z),.23,.21,materials.concrete)
	for x in range(int(a.x)+10,int(b.x)-10,16):
		geometry.road(Vector3(x,.12,bay.street_z+side*4.02),Vector3(x+7,.12,bay.street_z+side*4.02),.10,materials.paint)
func _plot_detail(item: Dictionary,index: int) -> void:
	var p: Vector3=item.position
	var basis:=Basis(Vector3.UP,item.angle)
	var size: Vector2=preload("res://game/scenery_plan.gd").SHAPES[item.kind]
	var front:=p+basis*Vector3(0,0,-size.y*.5)
	if item.kind in ["shop_row","shop_house","corner_shop"]:
		var sign_index:=index%SHOPS.size()
		var depth:=9.0 if item.kind=="shop_row" else 10.0
		var height:=3.10
		var sign_pos:=p+basis*Vector3(0,height,-depth*.5-.175)
		_text(SHOPS[sign_index],sign_pos+Vector3.UP*.13,.28,Color(.86,.85,.73),item.angle+PI)
		if index%2==0: _text(TAMIL[sign_index],sign_pos-Vector3.UP*.20,.23,Color(.90,.79,.39),item.angle+PI)
		if index%3==0:
			# Crates under the shop awning and a low bench beside the entrance.
			geometry.box(Vector3(1.1,.22,.38),front+basis*Vector3(size.x*.27,.55,-.20),materials.wall,Vector3(0,item.angle,0))
			geometry.box(Vector3(.46,.55,.42),front+basis*Vector3(-size.x*.30,.28,.15),materials.brick,Vector3(0,item.angle,0))
	elif item.kind=="temple_gateway":
		for side in [-1,1]:
			geometry.box(Vector3(7.2,1.8,.25),p+basis*Vector3(side*7.8,.9,-2.0),materials.wall,Vector3(0,item.angle,0))
			geometry.box(Vector3(.25,1.8,35),p+basis*Vector3(side*11.5,.9,15.5),materials.wall,Vector3(0,item.angle,0))
			for z in range(0,34,2):
				geometry.box(Vector3(.28,1.75,.55),p+basis*Vector3(side*11.5,.88,z),materials.brick,Vector3(0,item.angle,0))
		geometry.box(Vector3(23,1.8,.25),p+basis*Vector3(0,.9,33),materials.wall,Vector3(0,item.angle,0))
	elif item.kind=="temple_hall":
		pass
	elif item.kind=="school_block":
		_text("GOVERNMENT HIGHER SECONDARY SCHOOL",p+basis*Vector3(0,6.0,-4.66),.26,Color(.10,.14,.12),item.angle+PI)
	elif item.kind in ["rice_mill","warehouse","workshop"]:
		_text("KAVERI RICE MILL" if item.kind=="rice_mill" else ("ENGINEERING WORKS" if item.kind=="workshop" else "GOODS WAREHOUSE"),p+basis*Vector3(0,4.65,-size.y*.5+3.2),.42,Color(.76,.74,.62),item.angle+PI)
	elif index%3!=0 and item.kind!="water_tower":
		var wall_material: Material=materials.brick if index%4==0 else materials.wall
		var half:=size.x*.5+.2
		var z0: float=-size.y*.5-.12
		var z1: float=size.y*.5+.10
		# A front gate opening and short side returns keep each plot legible.
		for sign in [-1,1]:
			var a:=p+basis*Vector3(sign*1.25,.56,z0)
			var b:=p+basis*Vector3(sign*half,.56,z0)
			geometry.line(a,b,.17,1.10,wall_material)
			geometry.line(p+basis*Vector3(sign*half,.56,z0),p+basis*Vector3(sign*half,.56,z1),.17,1.10,wall_material)
			geometry.box(Vector3(.27,1.35,.28),p+basis*Vector3(sign*1.25,.675,z0),materials.concrete,Vector3(0,item.angle,0))
		if index%5==0:
			geometry.road(front+basis*Vector3(0,.13,0),front+basis*Vector3(0,.13,-3.0),2.0,materials.paving)
func _text(content: String,p: Vector3,size: float,colour: Color,angle: float) -> void:
	var label:=Label3D.new()
	label.text=content
	label.font=font
	label.font_size=72
	label.pixel_size=size/72.0
	label.outline_size=0
	label.modulate=colour
	label.position=p
	label.rotation.y=angle
	label.visibility_range_end=220
	label.visibility_range_end_margin=15
	label.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	view.root.add_child(label)
func _wires() -> void:
	var rows:={}
	for prop in plan.props:
		if prop.kind!="utility_pole": continue
		var key:=roundi(prop.position.z*10)
		if not rows.has(key): rows[key]=[]
		rows[key].append(prop.position)
	for points in rows.values():
		points.sort_custom(func(a,b):return a.x<b.x)
		for i in range(1,points.size()):
			var a: Vector3=points[i-1]
			var b: Vector3=points[i]
			if a.distance_to(b)>65: continue
			for cable in [-.70,0,.70]:
				var prior:=a+Vector3(0,6.45,cable)
				for step in range(1,7):
					var t:=step/6.0
					var next:=a.lerp(b,t)+Vector3(0,6.45-sin(t*PI)*.70,cable)
					geometry.line(prior,next,.016,.016,materials.wire)
					prior=next
func _field(item: Dictionary) -> void:
	var rect: Rect2=item.rect
	geometry.plane(rect,.024,materials["field%d"%item.stage])
	var p:=rect.position
	var q:=rect.end
	for edge in [[Vector3(p.x,.12,p.y),Vector3(q.x,.12,p.y)],[Vector3(q.x,.12,p.y),Vector3(q.x,.12,q.y)],[Vector3(q.x,.12,q.y),Vector3(p.x,.12,q.y)],[Vector3(p.x,.12,q.y),Vector3(p.x,.12,p.y)]]:
		geometry.line(edge[0],edge[1],.78,.24,materials.yard)
	# An irrigation feeder runs beside one long boundary, below the low earth bund.
	geometry.plane(Rect2(p.x,p.y-2.1,rect.size.x,.85),.009,materials.water)
