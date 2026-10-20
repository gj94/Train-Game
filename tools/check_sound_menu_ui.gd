extends SceneTree
const Menu:=preload("res://game/audio_menu.gd")
var failures:=0
var checks:=0

class Controller extends RefCounted:
	func remember_overlay_entry(_name: String) -> void:pass
class Dispatcher extends RefCounted:
	func set_open(_value: bool) -> void:pass
class Harness extends Node:
	var hud
	var controller:=Controller.new()
	var dispatcher:=Dispatcher.new()
	var audio_options=preload("res://game/audio_preferences.gd").new("user://menu-test-absent.cfg")
	var audio=preload("res://game/platform_audio.gd").new()
	var save_load
	var train_audio:={}
	func _set_paused(_paused: bool) -> void:pass

func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr(label)
func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.local/sound-menu/"+name+".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.local/sound-menu"))
	root.size=Vector2i(1280,720)
	var game:=Harness.new();root.add_child(game)
	game.hud=preload("res://game/hud.gd").new();game.add_child(game.hud)
	game.hud.clean_view=true
	game.save_load=preload("res://game/save_load.gd").new(game)
	Menu.show(game)
	await process_frame;await process_frame
	check(game.hud._heading.text=="SOUND MIXER","Main sound page")
	await shot("overview")
	for group in Menu.GROUPS:
		Menu.show(game,group);await process_frame;await process_frame
		for key in Menu.GROUPS[group].keys:
			check(game.hud.save_menu.options.any(func(entry):return entry[1]=="audio:layer:"+key),"Reachable "+key)
			Menu.show(game,key);await process_frame;await process_frame
			check(game.hud.save_menu.back_action=="audio:group:"+group,"Back to correct group for "+key)
			check(game.hud.save_menu.options.any(func(entry):return entry[1]=="audio:mute:"+key),"Independent mute "+key)
			Menu.show(game,group);await process_frame
	Menu.show(game,"rail");await process_frame;await shot("rail")
	Menu.show(game,"wind");await process_frame;await shot("wind")
	# Real native focus navigation, including scrolling below the modal fold.
	Menu.show(game,"levels");await process_frame;await process_frame
	game.hud.focus_first()
	for i in game.hud._buttons.get_child_count():
		var focus:=root.gui_get_focus_owner()
		check(focus is Button and focus.is_visible_in_tree(),"Focusable sound row")
		var next:=focus.find_valid_focus_neighbor(SIDE_BOTTOM)
		if next!=null:next.grab_focus()
		await process_frame
	game.audio.free();game.queue_free();await process_frame
	preload("res://game/audio_preferences.gd").new()
	print("Sound menu: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
