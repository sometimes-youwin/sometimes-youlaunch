class_name Metadata
extends Resource

const SAVE_PATH := "user://metadata.tres"

@export
var default_search_path := ""
@export
var launchables: Array[Launchable] = []

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

func _verify_sublaunchable(data: Sublaunchable) -> Error:
	var found := find_match(data.launchable)
	if found == null:
		printerr("Sublaunchable {0} refers to launchable that does not exist {1}".format([
			data.name, data.launchable.name
		]))
		return ERR_DOES_NOT_EXIST
	
	data.launchable = found
	
	return OK

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

static func create() -> Metadata:
	var r: Resource = load(SAVE_PATH)
	if r == null or not r is Metadata:
		printerr("Unable to load metadata from {0}, creating new Metadata".format([SAVE_PATH]))
		r = Metadata.new()
	
	return r

func reset() -> void:
	default_search_path = ""
	launchables.clear()

func find_match(input: Launchable) -> Launchable:
	var found := launchables.filter(func(v: Launchable) -> bool:
		return v.name == input.name
	)
	if found.size() != 1:
		return null
	
	return found.front()

func update_launchable(input: Launchable) -> Error:
	var found := find_match(input)
	if input == null:
		return ERR_DOES_NOT_EXIST
	
	launchables.erase(found)
	launchables.push_back(input)
	
	return save()

func verify_launchables() -> Error:
	for i in launchables:
		if i is Sublaunchable:
			if _verify_sublaunchable(i) != OK:
				printerr("Error with sublaunchable {0}".format([i.name]))
		
		var errors := i.check()
		if not errors.is_empty():
			printerr("Launchable {0} has errors:".format([i.name]))
			for e in errors:
				printerr(e)
		
	return OK

func save() -> Error:
	verify_launchables()
	sort()
	
	return ResourceSaver.save(self, SAVE_PATH)

func sort() -> void:
	launchables.sort_custom(func(a: Launchable, b: Launchable) -> bool:
		if a.last_used_datetime.year < b.last_used_datetime.year:
			return false
		if a.last_used_datetime.month < b.last_used_datetime.month:
			return false
		if a.last_used_datetime.day < b.last_used_datetime.day:
			return false
		if a.last_used_datetime.hour < b.last_used_datetime.hour:
			return false
		if a.last_used_datetime.minute < b.last_used_datetime.minute:
			return false
		if a.last_used_datetime.second < b.last_used_datetime.second:
			return false
		
		return true
	)
