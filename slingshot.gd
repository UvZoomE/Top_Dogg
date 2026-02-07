class_name SlingShot
extends Node2D

enum SlingState {
	idle,
	pulling,
	characterThrown,
	reset,
}

@export var SlingShotState = SlingState.idle
var LeftLine
var RightLine
var CenterOfSlingshot

# Called when the node enters the scene tree for the first time.
func _ready():
	# Slingshot needs to start off in idle state
	SlingShotState = SlingState.idle
	# Dollar signs allow us to access nodes within our scene
	LeftLine = $LeftLine
	RightLine = $RightLine
	CenterOfSlingshot = $CenterOfSlingshot.position
	# There are two points to our lines, points[1] will eventually be attached to the player
	LeftLine.points[1] = CenterOfSlingshot
	RightLine.points[1] = CenterOfSlingshot
	# Grab the player in the node group from the Player scene where each player is created
	var player = get_tree().get_nodes_in_group("Player")[0]
	player.position = CenterOfSlingshot
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Each frame check the sling shot state
	var tile = get_tree().get_first_node_in_group("Tile")
	match SlingShotState:
		SlingState.idle:
			pass
		SlingState.pulling:
			var player = get_tree().get_nodes_in_group("Player")[0] as RigidBody2D
			if Input.is_action_pressed("Left_Mouse"):
				var mousepos = get_global_mouse_position()
				# Normalize the sling to only go '100' distance away from the center
				if mousepos.distance_to(CenterOfSlingshot) > 200:
					mousepos = (mousepos - CenterOfSlingshot).normalized() * 200 + CenterOfSlingshot
				player.position = mousepos
				LeftLine.points[1] = mousepos
				RightLine.points[1] = mousepos
				
			else:
				var location = get_global_mouse_position()
				var distance = location.distance_to(CenterOfSlingshot)
				var velocity = CenterOfSlingshot - location				
				# Lets get player.gd script
				player.ThrowPlayer()
				# Smooth out the velocity for the player
				player.linear_velocity = velocity
				# Mess with speed of player here after throw
				player.apply_central_impulse(velocity * 12)
				# After throw, do not come back to 'pulling' state again but go to characterThrown state
				SlingShotState = SlingState.characterThrown
				# Reset lines to center
				LeftLine.points[1] = CenterOfSlingshot
				RightLine.points[1] = CenterOfSlingshot
				get_tree().get_nodes_in_group("Camera")[0].followingPlayer = true
		SlingState.characterThrown:
			pass
		SlingState.reset:
			pass
	
	pass


func _on_touch_area_input_event(viewport, event, shape_idx):
	# If SlingShotState is intially idle and a touch event occurred, change state to pulling
	if SlingShotState == SlingState.idle:
		if (event as InputEventMouseButton && event.pressed):
			SlingShotState = SlingState.pulling
	pass # Replace with function body.
