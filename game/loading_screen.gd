extends Control
## Honest scenery work counters, not an estimated time-to-ready percentage.
const Style:=preload("res://game/menu_theme.gd")
var detail: Label
var _progress: ProgressBar
var _count: Label
var _phases: Label
var _elapsed: Label
var _since:=Time.get_ticks_msec()
func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT);theme=Style.theme();mouse_filter=MOUSE_FILTER_STOP
	var bg:=ColorRect.new();bg.color=Style.INK;add_child(bg);bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var center:=CenterContainer.new();add_child(center);center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var panel:=PanelContainer.new();panel.custom_minimum_size.x=860;center.add_child(panel)
	panel.add_theme_stylebox_override("panel",Style.box(Style.SURFACE,36))
	var body:=VBoxContainer.new();body.add_theme_constant_override("separation",22);panel.add_child(body)
	Style.label(body,"KERALA COAST  /  PREPARING YOUR JOURNEY",13,Style.ACCENT)
	Style.label(body,"Bringing the railway into view",32)
	detail=Style.label(body,"Preparing nearby scenery…",20);detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_progress=ProgressBar.new();_progress.custom_minimum_size.y=6;_progress.show_percentage=false
	_progress.add_theme_stylebox_override("background",Style.box(Style.INK,0))
	_progress.add_theme_stylebox_override("fill",Style.box(Style.ACCENT,0,Style.ACCENT));body.add_child(_progress)
	_count=Style.label(body,"",16)
	_phases=Style.label(body,"",16,Style.MUTED);_phases.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	Style.divider(body)
	Style.label(body,"Large stations can take longer than individual scenery sections.\nThe railway clock stays paused until your surroundings are ready.",15,Style.MUTED)
	_elapsed=Style.label(body,"",13,Style.MUTED)
	var version:=Style.label(self,preload("res://game/build_version.gd").current(),14,Style.MUTED)
	version.name="BuildVersion";version.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
	version.offset_top=-68;version.offset_bottom=-42;version.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var credit:=Style.label(self,"Map data © OpenStreetMap contributors · ODbL 1.0    /    Terrain: NASA / USGS SRTM",12,Style.MUTED)
	credit.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE);credit.offset_top=-38;credit.offset_bottom=-14
	credit.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
func report(completed: int, required: int, assets: String, generating: int, waiting: int, attaching: int) -> void:
	_progress.max_value=maxi(1,required);_progress.value=completed
	_count.text="%d of %d nearby sections ready" % [completed,required]
	detail.text="Loading station assets · "+assets if not assets.is_empty() else ("Building nearby scenery" if generating>0 else ("Attaching scenery to the world" if attaching>0 else "Preparing nearby scenery"))
	_phases.text="Queued  %d     Building  %d     Attaching  %d sections" % [waiting,generating,attaching]
	_elapsed.text="Elapsed %ds  ·  Preparing your immediate surroundings. Distant scenery continues in the background." % ((Time.get_ticks_msec()-_since)/1000)
