extends Button

func _pressed():
	var leaderboard = get_tree().get_first_node_in_group("Leaderboard") as TextureRect
	leaderboard.visible = true
	
	if leaderboard.has_method("_load_entries"):
		leaderboard._load_entries()
	else:
		print("ERROR: Could not find _load_entries on the leaderboard!")
	
	var header_text = get_tree().get_nodes_in_group("HeaderText")[0] as Label
	var play_button = get_tree().get_first_node_in_group("PlayButton")
	header_text.text = "Leaderboard"
	# The big menu title is too tall for the board view, so shrink it.
	header_text.add_theme_font_size_override("font_size", 44)
	play_button.visible = false
	self.visible = false
	%Control4.visible = false
	%BackButton.visible = true
	%MenuTagline.visible = false
	%PodiumIcon.visible = true
	
	# Fade in the window behind the board (it is invisible on the main menu).
	%PanelBg.visible = true
	%PanelBg.modulate.a = 0.0
	create_tween().tween_property(%PanelBg, "modulate:a", 1.0, 0.25)
