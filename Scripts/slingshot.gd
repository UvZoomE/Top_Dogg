class_name SlingShot
extends Node2D

enum SlingState {
	idle,
	pulling,
	characterThrown,
	reset,
}

@export var SlingShotState = SlingState.idle
var LeftLine: Line2D
var RightLine: Line2D
var CenterOfSlingshot: Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	# Slingshot needs to start off in idle state
	SlingShotState = SlingState.idle
	# Dollar signs allow us to access nodes within our scene
	LeftLine = $LeftLine as Line2D
	RightLine = $RightLine as Line2D
	CenterOfSlingshot = $CenterOfSlingshot.position
	# There are two points to our lines, point 1 will eventually be attached to the player
	# NOTE: use set_point_position() - writing to `line.points[1]` only edits a temporary copy
	LeftLine.set_point_position(1, CenterOfSlingshot)
	RightLine.set_point_position(1, CenterOfSlingshot)
	# Grab the player in the node group from the Player scene where each player is created
	var player = get_tree().get_nodes_in_group("Player")[0]
	player.position = CenterOfSlingshot


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# Each frame check the sling shot state
	match SlingShotState:
		SlingState.idle:
			pass
		SlingState.pulling:
			var player = get_tree().get_nodes_in_group("Player")[0] as RigidBody2D
			if Input.is_action_pressed("Left_Mouse"):
				var mousepos = get_global_mouse_position()
				# Normalize the sling to only go '200' distance away from the center
				if mousepos.distance_to(CenterOfSlingshot) > 200:
					mousepos = (mousepos - CenterOfSlingshot).normalized() * 200 + CenterOfSlingshot
				player.position = mousepos
				LeftLine.set_point_position(1, mousepos)
				RightLine.set_point_position(1, mousepos)
			else:
				var launch_pos = get_global_mouse_position()
				var velocity = CenterOfSlingshot - launch_pos
				# Lets get player.gd script
				player.ThrowPlayer()
				# Smooth out the velocity for the player
				player.linear_velocity = velocity
				# Mess with speed of player here after throw
				player.apply_central_impulse(velocity * 12)
				# After throw, do not come back to 'pulling' state again but go to characterThrown state
				SlingShotState = SlingState.characterThrown
				# Reset lines to center
				LeftLine.set_point_position(1, CenterOfSlingshot)
				RightLine.set_point_position(1, CenterOfSlingshot)
				get_tree().get_nodes_in_group("Camera")[0].followingPlayer = true
		SlingState.characterThrown:
			pass
		SlingState.reset:
			pass


## Signal connected via the editor — viewport/shape_idx intentionally unused.
@warning_ignore("unused_parameter")
func _on_touch_area_input_event(viewport, event, shape_idx):
	# If SlingShotState is initially idle and a touch event occurred, change state to pulling
	if SlingShotState == SlingState.idle:
		if (event as InputEventMouseButton && event.pressed):
			SlingShotState = SlingState.pulling
