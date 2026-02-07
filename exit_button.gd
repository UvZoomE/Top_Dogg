extends Button
@export var leaderboard_name: String
@onready var player = get_tree().get_first_node_in_group("Player") as RigidBody2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _pressed():
	var chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var result = ""
	
	# Loop 8 times (or whatever length you pass in)
	for i in range(8):
		var random_index = randi() % chars.length()
		result += chars[random_index]
	
	await Talo.players.identify("username", result)
	var score = player.position.x
	var res := await Talo.leaderboards.add_entry(leaderboard_name, score)
	print(res.entry.score)
	get_tree().change_scene_to_file("res://main_menu.tscn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
