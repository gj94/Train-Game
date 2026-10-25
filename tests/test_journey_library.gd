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

func test_preferences_keep_all_registered_operating_days_separate():
	DirAccess.make_dir_recursive_absolute("res://.local/r45")
	var library:=Library.new();var days:=preload("res://persistence/operating_days.gd").DAYS
	for i in days.size():
		library.selections[days[i].id]="SERVICE"+str(i)
		library.toggle(days[i].id,"SHARED")
	library.timetable="network_v2"
	var config:=ConfigFile.new();library.write(config)
	if config.save(PATH)!=OK:return "Could not save isolated preferences"
	var restored:=Library.new();restored.restore(PATH);DirAccess.remove_absolute(PATH)
	if restored.timetable!="network_v2":return "New operating day was reset"
	for i in days.size():
		if restored.selections.get(days[i].id,"")!="SERVICE"+str(i) or not restored.favourite(days[i].id,"SHARED"):return "Operating-day selection lost: "+days[i].id
	return true

func test_full_route_includes_boundary_workings_covering_both_map_termini():
	var library:=Library.new();library.through_only=true
	var service:=row("M061")
	service.origin="Enters railway north of ERS";service.destination="Continues south beyond NCJ"
	service.calls=[{name=service.origin,boundary="entry"},{name="Ernakulam Junction"},{name="Thiruvananthapuram Central"},{name="Nagercoil Junction"},{name=service.destination,boundary="exit"}]
	var original:=service.duplicate(true)
	if not library.accepts(service,"network",""):return "Full-corridor through working was hidden"
	if service!=original:return "Browsing mutated source metadata"
	service.calls.remove_at(3);service.destination="Thiruvananthapuram Central"
	return not library.accepts(service,"network","")
