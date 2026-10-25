extends RefCounted
## Local browsing preferences only. Never writes authored services or railway state.
const STOCK_KEYS:=["","icf","lhb","vb8","vb16"]
const STOCK_LABELS:=["All trains","WAP-7 + ICF","WAP-7 + LHB","Vande Bharat · 8","Vande Bharat · 16"]
const Days:=preload("res://persistence/operating_days.gd")
var favourites: Array[String]=[]
var selections: Dictionary={}
var timetable:="standard"
var stock:=""
var favourites_only:=false
var through_only:=false

func restore(path: String) -> void:
	var config:=ConfigFile.new()
	if config.load(path)!=OK:return
	timetable=str(config.get_value("library","timetable","standard"))
	if not Days.DAYS.any(func(day):return day.id==timetable):timetable="standard"
	stock=str(config.get_value("library","stock",""))
	if stock not in STOCK_KEYS:stock=""
	favourites_only=config.get_value("library","favourites_only",false)==true
	through_only=config.get_value("library","through_only",false)==true
	favourites.clear();selections.clear()
	var entries=config.get_value("library","favourites",[])
	if entries is Array:
		for entry in entries.slice(0,512):
			if entry is String and entry.length()<100 and entry.count(":")==1 and entry not in favourites:favourites.append(entry)
	var remembered=config.get_value("library","selections",{})
	if remembered is Dictionary:
		for day in Days.DAYS:
			var id=remembered.get(day.id,"K1")
			if id is String and id.is_valid_identifier():selections[day.id]=id

func write(config: ConfigFile) -> void:
	for key in ["timetable","stock","favourites_only","through_only","favourites","selections"]:config.set_value("library",key,get(key))

func favourite(day: String,id: String) -> bool:
	return day+":"+id in favourites

func toggle(day: String,id: String) -> void:
	var key:=day+":"+id
	if key in favourites:favourites.erase(key)
	else:favourites.append(key)

func accepts(row: Dictionary, day: String, query: String) -> bool:
	if not stock.is_empty() and row.get("stock","")!=stock:return false
	if favourites_only and not favourite(day,row.id):return false
	if through_only and not covers_full_route(row):return false
	var haystack: String=(row.get("name","")+" "+row.id+" "+row.get("origin","")+" "+row.get("destination","")+" "+row.get("stock","")).to_lower()
	# Match visible stock names and station calls as independent search words.
	if row.get("stock","") in ["vb8","vb16"]:haystack+=" vande bharat"
	elif row.get("stock","") in ["icf","lhb"]:haystack+=" wap-7 wap7"
	for call in row.get("calls",[]):haystack+=" "+str(call.get("name","")).to_lower()
	for word in query.to_lower().replace("\t"," ").replace("\n"," ").replace("+"," ").split(" ",false):
		if not haystack.contains(word):return false
	return true

static func covers_full_route(row: Dictionary) -> bool:
	# A distant origin/destination may lie beyond the map. Match the actual
	# on-map calls as well as the endpoints retained by older catalogues.
	var names: Array=[row.get("origin",""),row.get("destination","")]
	for call in row.get("calls",[]):
		if not call.has("boundary"):names.append(call.get("name",""))
	return "Ernakulam Junction" in names and "Nagercoil Junction" in names
