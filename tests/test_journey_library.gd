extends RefCounted
const Library:=preload("res://game/journey_library.gd")
const PATH:="res://.local/r45/library-test.cfg"
func row(id: String="K1") -> Dictionary:
	return {id=id,name="Coastal stopping passenger",stock="icf",origin="Ernakulam Junction",destination="Nagercoil Junction",distance_m=276459,calls=[{name="Alappuzha"},{name="Thiruvananthapuram Central"}]}

func test_queries_combine_train_and_calling_stations_without_changing_source():
	var library:=Library.new();var service:=row();var original:=service.duplicate(true)
	return library.accepts(service,"standard","ICF alappuzha") and library.accepts(service,"standard","WAP-7 + ICF") and not library.accepts(service,"standard","ICF Chennai") and service==original

func test_full_route_requires_both_termini_in_either_direction():
	var library:=Library.new();library.through_only=true
	var service:=row();var ok:=library.accepts(service,"standard","")
	service.origin="Nagercoil Junction";service.destination="Ernakulam Junction"
	ok=ok and library.accepts(service,"standard","")
	service.destination="Ernakulam Town"
	return ok and not library.accepts(service,"standard","")

func test_favourites_keep_operating_days_separate_and_combine_filters():
	var library:=Library.new();library.toggle("standard","K1");library.favourites_only=true
	var ok:=library.accepts(row(),"standard","") and not library.accepts(row(),"intensive","")
	library.stock="lhb";ok=ok and not library.accepts(row(),"standard","")
	library.stock="";library.toggle("standard","K1")
	return ok and not library.accepts(row(),"standard","")

func test_preferences_preserve_per_day_selection_and_legacy_values():
	DirAccess.make_dir_recursive_absolute("res://.local/r45")
	var library:=Library.new();library.toggle("intensive","B042");library.selections={standard="K3",intensive="B042"};library.timetable="intensive";library.stock="vb16";library.through_only=true
	var config:=ConfigFile.new();config.set_value("browser","search","Night");library.write(config)
	if config.save(PATH)!=OK:return "Could not create isolated fixture preferences"
	var restored:=Library.new();restored.restore(PATH)
	var verify:=ConfigFile.new();verify.load(PATH);DirAccess.remove_absolute(PATH)
	return restored.timetable=="intensive" and restored.stock=="vb16" and restored.through_only and restored.favourite("intensive","B042") and restored.selections.standard=="K3" and verify.get_value("browser","search")=="Night"

func test_invalid_preferences_do_not_activate_unknown_filters():
	DirAccess.make_dir_recursive_absolute("res://.local/r45")
	var config:=ConfigFile.new();config.set_value("library","stock","unknown");config.set_value("library","timetable","missing")
	config.set_value("library","favourites",[2,"standard:K1","standard:K1",{}]);config.set_value("library","selections",{standard=4,intensive="B002"})
	if config.save(PATH)!=OK:return "Could not create isolated fixture preferences"
	var library:=Library.new();library.restore(PATH);DirAccess.remove_absolute(PATH)
	return library.stock.is_empty() and library.timetable=="standard" and library.favourites==["standard:K1"] and not library.selections.has("standard") and library.selections.intensive=="B002"
