extends RefCounted
## Borderless fullscreen on the current monitor, with a remembered window mode.
var settings_path := "user://display.cfg"
var window_mode := DisplayServer.WINDOW_MODE_WINDOWED
var window_size := Vector2i(1280,720)
var window_position := Vector2i.ZERO

func is_fullscreen() -> bool:
	return DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN,DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]

func restore() -> void:
	var config:=ConfigFile.new()
	var found:=config.load(settings_path)==OK
	var fullscreen: bool=config.get_value("display","fullscreen",OS.has_feature("template")) if found else OS.has_feature("template")
	if fullscreen and not is_fullscreen():toggle(false)

func toggle(save: bool=true) -> Error:
	if DisplayServer.get_name()=="headless":return OK
	if is_fullscreen():
		DisplayServer.window_set_mode(window_mode)
		if window_mode==DisplayServer.WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_size(window_size)
			DisplayServer.window_set_position(window_position)
	else:
		window_mode=DisplayServer.window_get_mode()
		if window_mode not in [DisplayServer.WINDOW_MODE_WINDOWED,DisplayServer.WINDOW_MODE_MAXIMIZED]:window_mode=DisplayServer.WINDOW_MODE_WINDOWED
		window_size=DisplayServer.window_get_size()
		window_position=DisplayServer.window_get_position()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	if not save:return OK
	var config:=ConfigFile.new()
	config.set_value("display","fullscreen",is_fullscreen())
	return config.save(settings_path)
