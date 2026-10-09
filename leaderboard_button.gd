extends Button

func _pressed():
	var leaderboard = get_tree().get_first_node_in_group("Leaderboard") as TextureRect
	leaderboard.visible = true
	
	if leaderboard.has_method("_load_entries"):
		leaderboard._load_entries()
	else:
		print("ERROR: Could not find _load_entries on the leaderboard!")
	
	var text = get_tree().get_nodes_in_group("HeaderText")[0] as Label
	var play_button = get_tree().get_first_node_in_group("PlayButton")
	text.text = "Leaderboard"
	play_button.visible = false
	self.visible = false
	%Control4.visible = false
	%BackButton.visible = true
