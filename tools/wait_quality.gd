extends RefCounted
## Per-stop wait quality, excluding normal dwell and user-imposed pauses.
## Cumulative targets: better-than-requested distributions also pass.
const MINIMUM_SECONDS := 30.0
const LIMITS := [600.0,1200.0,1800.0,2700.0]
const FRACTIONS := [.70,.90,.98,1.0]

static func summarize(rows: Array) -> Dictionary:
	var waits: Array=rows.filter(func(r):return r.seconds>=MINIMUM_SECONDS)
	var bins:=[0,0,0,0,0];var cumulative:=[];var passed:=true;var maximum:=0.0
	for row in waits:
		maximum=maxf(maximum,row.seconds)
		var bin:=4
		for i in LIMITS.size():
			if row.seconds<LIMITS[i]:bin=i;break
		bins[bin]+=1
	var count:=0
	for i in LIMITS.size():
		count+=bins[i]
		var fraction:=float(count)/waits.size() if not waits.is_empty() else 1.0
		var met:=count>=ceili(waits.size()*FRACTIONS[i]-1e-9)
		cumulative.append({under_seconds=LIMITS[i],required=FRACTIONS[i],count=count,fraction=fraction,met=met})
		passed=passed and met
	return {ok=passed,minimum_seconds=MINIMUM_SECONDS,count=waits.size(),brief_count=rows.size()-waits.size(),bins=bins,cumulative=cumulative,maximum=maximum}
