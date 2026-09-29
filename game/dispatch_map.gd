extends Control
## Schematic presentation only. Every colour and reservation comes from RailWorld.

signal signal_selected(id: String)
signal destination_selected(id: String)
var world: RailWorld
var selected := ""
var destination := ""
const INK := Color("789098")
const TEAL := Color("52dcc4")
const GOLD := Color("ffca72")
const RED := Color("ff7868")
const ROADS := {
	"cpm_p1": [Vector2(60, 74), Vector2(270, 74)],
	"cpm_p2": [Vector2(60, 139), Vector2(200, 139), Vector2(270, 74)],
	"main_w": [Vector2(270, 74), Vector2(600, 74)],
	"mrt_main": [Vector2(600, 74), Vector2(930, 74)],
	"mrt_loop": [Vector2(600, 74), Vector2(658, 139), Vector2(872, 139), Vector2(930, 74)],
	"main_e": [Vector2(930, 74), Vector2(1230, 74)],
	"kdp_plat": [Vector2(1230, 74), Vector2(1440, 74)],
}
const SIGNAL_POS := {
	"CPM-S1": Vector2(236, 74), "CPM-S2": Vector2(218, 122),
	"CPM-H": Vector2(310, 74), "MRT-HE": Vector2(563, 74),
	"MRT-SE1": Vector2(839, 74), "MRT-SW1": Vector2(690, 74),
	"MRT-SE2": Vector2(838, 139), "MRT-SW2": Vector2(692, 139),
	"MRT-HW": Vector2(971, 74), "KDP-H": Vector2(1196, 74), "KDP-S": Vector2(1271, 74),
}
var _hits := {}

func _ready() -> void:
	custom_minimum_size = Vector2(0, 190)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _point(edge: String, fraction: float) -> Vector2:
	var pts: Array = ROADS[edge]
	var total := 0.0
	for i in pts.size() - 1:
		total += pts[i].distance_to(pts[i + 1])
	var distance := total * clampf(fraction, 0.0, 1.0)
	for i in pts.size() - 1:
		var length: float = pts[i].distance_to(pts[i + 1])
		if distance <= length:
			return pts[i].lerp(pts[i + 1], distance / length)
		distance -= length
	return pts[-1]

func _text(pos: Vector2, text: String, color: Color, font_size: int = 14) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw() -> void:
	if world == null:
		return
	draw_set_transform(Vector2.ZERO, 0, Vector2(size.x / 1500.0, 1))
	_hits.clear()
	_text(Vector2(60, 19), "01  CHENNAPURAM", GOLD, 17)
	_text(Vector2(663, 19), "02  MARUTHUR", GOLD, 17)
	_text(Vector2(1230, 19), "03  KADALUR", GOLD, 17)
	_text(Vector2(365, 165), "WEST SINGLE-LINE BLOCK", INK, 12)
	_text(Vector2(1000, 165), "EAST SINGLE-LINE BLOCK", INK, 12)
	_text(Vector2(729, 56), "P1 / MAIN", INK, 12)
	_text(Vector2(729, 123), "P2 / LOOP", INK, 12)
	var occ := world.occupancy()
	var reserved := {}
	for sig in world.signals.values():
		for r in sig.route:
			reserved[r.edge] = true
	for edge in ROADS:
		var points := PackedVector2Array(ROADS[edge])
		draw_polyline(points, Color("233e49"), 10, true)
		var color := RED if occ.has(edge) else (TEAL if reserved.has(edge) else INK)
		draw_polyline(points, color, 4, true)
	for sid in SIGNAL_POS:
		var p: Vector2 = SIGNAL_POS[sid]
		var dir: int = world.signals[sid].dir
		var lower: bool = dir < 0 or sid.ends_with("2")
		var lamp := p + Vector2(0, 14 if lower else -14)
		var color: Color = [RED, GOLD, TEAL][world.aspect(sid)]
		draw_line(p, lamp, INK, 1)
		draw_circle(lamp, 5.5, color)
		if sid == selected or sid == destination:
			draw_arc(lamp, 10, 0, TAU, 32, Color.WHITE if sid == selected else TEAL, 2, true)
		draw_line(lamp + Vector2(dir * 9, -4), lamp + Vector2(dir * 13, 0), color, 2)
		draw_line(lamp + Vector2(dir * 9, 4), lamp + Vector2(dir * 13, 0), color, 2)
		_text(lamp + Vector2(-31, 22 if lower else -12), sid, Color("d5e2e5"), 12)
		_hits[sid] = Rect2(lamp - Vector2(30, 12), Vector2(65, 38))
	for t in world.trains.values():
		var edge: String = t.path[0].edge
		# Compress the long terminal point lead in this schematic, keeping a
		# train waiting at its starter visibly behind that signal.
		var fraction: float = t.head_s / world.graph.edges[edge].length
		if edge in ["cpm_p1", "cpm_p2"]:
			fraction = t.head_s / 370.0 if t.head_s < 310.0 else lerpf(310.0 / 370.0, 1.0, (t.head_s - 310.0) / (world.graph.edges[edge].length - 310.0))
		var p := _point(edge, fraction)
		var rect := Rect2(p - Vector2(25, 10), Vector2(50, 20))
		draw_style_box(_train_style(), rect)
		_text(p + Vector2(-20, 5), "%s %s" % [t.id, ">" if t.path[0].dir > 0 else "<"], Color("10252d"), 14)
	for endpoint in [{id = "CPM_B1", p = Vector2(60, 74)}, {id = "CPM_B2", p = Vector2(60, 139)}, {id = "KDP_B", p = Vector2(1440, 74)}]:
		draw_line(endpoint.p + Vector2(0, -8), endpoint.p + Vector2(0, 8), GOLD, 3)
		_hits["BUFFER:" + endpoint.id] = Rect2(endpoint.p - Vector2(15, 15), Vector2(30, 30))

func _train_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = GOLD
	style.set_corner_radius_all(4)
	return style

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = event.position / Vector2(size.x / 1500.0, 1)
		for id in _hits:
			if _hits[id].has_point(p):
				if id.begins_with("BUFFER:"):
					destination_selected.emit(id)
				else:
					signal_selected.emit(id)
				accept_event()
				return
