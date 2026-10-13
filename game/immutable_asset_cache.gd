extends RefCounted
## A bounded shared cache; consumers keep their own strong resource references.
## Construct outside the lock, then publish once. No scene-tree work under lock.
var _entries:={}
var _order: Array[String]=[]
var _mutex:=Mutex.new()
var _capacity: int
var _prefix: String

func _init(capacity: int,prefix: String="") -> void:
	_capacity=maxi(1,capacity);_prefix=prefix

func contains(key: String) -> bool:
	_mutex.lock();var present:=_entries.has(key);_mutex.unlock();return present

func fetch(key: String) -> Dictionary:
	_mutex.lock()
	var result: Dictionary=_entries.get(key,{})
	var retired: Array=_touch(key) if not result.is_empty() else []
	_mutex.unlock();retired.clear();return result

func publish(key: String,value: Dictionary) -> Dictionary:
	_mutex.lock()
	if not _entries.has(key):_entries[key]=value
	var result: Dictionary=_entries[key]
	var retired:=_touch(key)
	_mutex.unlock();retired.clear();return result

func _touch(key: String) -> Array:
	var retired:=[]
	if not key.begins_with(_prefix):return retired
	_order.erase(key);_order.append(key)
	while _order.size()>_capacity:
		var stale: String=_order.pop_front()
		retired.append(_entries[stale]);_entries.erase(stale)
	# Release potentially large renderer resources only after dropping the lock.
	return retired

func counts() -> Dictionary:
	_mutex.lock();var result:={entries=_entries.size(),bounded=_order.size(),capacity=_capacity};_mutex.unlock();return result
