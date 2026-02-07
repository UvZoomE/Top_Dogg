extends Camera2D

var startingPos
var player
var followingPlayer
# Called when the node enters the scene tree for the first time.
func _ready():
	startingPos = global_position
	player = get_tree().get_nodes_in_group("Player")[0]
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if followingPlayer:
		if is_instance_valid(player):
			var playerpos_x = clamp(player.position.x, 0, 100000)
			var playerpos_y = min(player.position.y, startingPos.y)
			
			global_position = Vector2(playerpos_x, playerpos_y)
		else:
			followingPlayer = false
			var tween = create_tween()
			tween.tween_property(self, "position", startingPos, 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			
	pass
