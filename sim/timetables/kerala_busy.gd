extends RefCounted
## Fictional 100-working operating day. Real route/stock limits and CSV platforms.
## North and south single-line sectors use wider departure intervals than the
## central double line. All termini have signalled empty-stock access to depot.
const COUNT := 100
static func definitions(w) -> Array:
	var rows := [["K1","Coastal Stopping Passenger · Ernakulam to Nagercoil","icf",1,w.stations.filter(func(s):return s.passenger_open).map(func(s):return s.code),1,1,"08:00",20]]
	add_wave(rows,10,1,["ERS","TUVR","SRTL","ALLP","AMPA","HAD","KYJ"],8*60+12,30,"Coastal")
	add_wave(rows,10,-1,["KYJ","HAD","AMPA","ALLP","SRTL","TUVR","ERS"],8*60,30,"Coastal")
	add_wave(rows,30,1,["QLN","PVU","VAK","KZK","TVCN","TVC"],8*60+5,12,"Capital")
	add_wave(rows,30,-1,["TVC","TVCN","KZK","VAK","PVU","QLN"],8*60+11,12,"Capital")
	add_wave(rows,10,1,["TVC","NYY","PASA","KZT","ERL","NCJ"],8*60+25,40,"Cape")
	add_wave(rows,9,-1,["NCJ","ERL","KZT","PASA","NYY","TVC"],8*60+5,40,"Cape")
	assert(rows.size()==COUNT)
	return rows

static func add_wave(rows: Array, count: int, dir: int, calls: Array, first: int, headway: int, corridor: String) -> void:
	for n in count:
		var stock: String=["icf","lhb","vb8","lhb","icf","vb16"][n%6]
		var priority: int={"icf":35,"lhb":70,"vb8":95,"vb16":100}[stock]
		var label: String={"icf":"Passenger","lhb":"Intercity","vb8":"Vande Bharat 8","vb16":"Vande Bharat 16"}[stock]
		var stops: Array=calls.duplicate()
		# Expresses omit secondary calls, producing overtakes without speed caps.
		if stock.begins_with("vb"):
			stops=[calls[0],calls[calls.size()/2],calls[-1]]
		var minute: int=first+n*headway
		var origin: int=3 if dir>0 else 4
		# NCJ's P4 serves the southbound arrival; northbound supply uses P2.
		if calls[0]=="NCJ":origin=2
		rows.append(["B%03d" % rows.size(),"%s %s %02d · %s–%s" % [corridor,label,n+1,calls[0],calls[-1]],stock,dir,stops,origin,1 if dir>0 else 2,"%02d:%02d" % [minute/60,minute%60],priority])
