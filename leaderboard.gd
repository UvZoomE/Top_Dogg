extends TextureRect

var entry_scene = preload("res://leaderboard_entries.tscn") # update this to a path that matches your entry scene

@export var leaderboard_internal_name: String

@onready var entries_container: VBoxContainer = %Entries
@onready var control4: Control = %Control4
@onready var backbutton: Button = %BackButton

func _ready() -> void:
	print("1. Leaderboard _ready() called!")
	print("Leaderboard internal name is: '", leaderboard_internal_name, "'")
	
	if leaderboard_internal_name == "":
		push_error("ERROR: Leaderboard name is completely empty in the Inspector!")
		return # Stop running if there's no name
		
	await _load_entries()
	print("4. _load_entries() completely finished!")

func _build_entries() -> void:
	for child in entries_container.get_children():
		child.queue_free()
	
	for entry in Talo.leaderboards.get_cached_entries(leaderboard_internal_name):
		_create_entry(entry)

func _load_entries() -> void:
	print("2. _load_entries() started!")
	var page = 0
	var done = false

	while !done:
		var options := Talo.leaderboards.GetEntriesOptions.new()
		options.page = page

		print("3. Requesting Talo data for page ", page, "...")
		
		# If the code freezes, it will happen on this await line
		var res := await Talo.leaderboards.get_entries(leaderboard_internal_name, options)
		
		print("Talo Server Returned ", res.entries.size(), " entries for page ", page)
		
		var entries: Array[TaloLeaderboardEntry] = res.entries
		var count: int = res.count
		var is_last_page: bool = res.is_last_page

		if is_last_page:
			done = true
		else:
			page += 1

	_build_entries()

func _create_entry(entry: TaloLeaderboardEntry) -> void:
	var entry_instance = entry_scene.instantiate()
	
	# 2. BULLETPROOF NODE TARGETING: 
	# This checks if your script is on the Root node OR the First Child 
	# so it won't crash either way.
	if entry_instance.has_method("set_data"):
		entry_instance.set_data(entry.position, entry.player_alias.identifier, entry.score)
	elif entry_instance.get_child_count() > 0 and entry_instance.get_child(0).has_method("set_data"):
		entry_instance.get_child(0).set_data(entry.position, entry.player_alias.identifier, entry.score)
	else:
		push_error("ERROR: Could not find set_data method on leaderboard_entries.tscn")
		
	entries_container.add_child(entry_instance)
	print("Successfully added UI entry for: ", entry.player_alias.identifier)

func _on_submit_pressed() -> void:
	pass
