extends Button

func _pressed():
	var leaderboard = get_tree().get_first_node_in_group("Leaderboard") as TextureRect
	leaderboard.visible = true
	var text = get_tree().get_nodes_in_group("HeaderText")[0] as Label
	var play_button = get_tree().get_first_node_in_group("PlayButton")
	text.text = "Leaderboard"
	play_button.visible = false
	self.visible = false
