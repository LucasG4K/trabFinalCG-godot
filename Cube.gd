extends RigidBody3D

@export_category("Buoyancy")
@export var float_force := 1.0
@export var water_drag := 0.05
@export var water_angular_drag := 0.05

@export_category("Locomotion")
@export var paddle_force := 10.0
# Assign Marker3D nodes here in the inspector
@export var left_paddle_node: Node3D
@export var right_paddle_node: Node3D
@onready var left_paddle_animation: AnimationPlayer = $LeftPaddleAnimation
@onready var right_paddle_animation: AnimationPlayer = $RightPaddleAnimation

@export_category("Camera")
@export var view_camera: Camera3D
# Position relative to the boat where the camera tries to be
@export var camera_offset := Vector3(0, 5, 10)
# Higher = faster/tighter tracking, Lower = smoother/looser
@export var camera_smoothness := 2.0

@onready var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
# Ensure this path is correct for your scene tree
@onready var water = get_node('/root/Main/Water')
@onready var probes = $Probes.get_children()

var submerged := false

func _physics_process(delta):
	submerged = false
	
	# 1. Handle Buoyancy
	for p in probes:
		var depth = water.get_height(p.global_position) - p.global_position.y
		if depth > 0:
			submerged = true
			apply_force(Vector3.UP * float_force * gravity * depth, p.global_position - global_position)

	# 2. Handle Movement (Only if touching water)
	if submerged:
		handle_movement()

	# 3. Handle Camera Follow
	if view_camera:
		# Calculate where the camera should be (relative to the boat's current rotation)
		var target_position = global_position + (global_transform.basis * camera_offset)
		
		# Smoothly interpolate the camera's position towards the target
		view_camera.global_position = view_camera.global_position.lerp(target_position, delta * camera_smoothness)
		
		# Make the camera look at the boat
		view_camera.look_at(global_position, Vector3.UP)

func _integrate_forces(state: PhysicsDirectBodyState3D):
	if submerged:
		state.linear_velocity *=  1 - water_drag
		state.angular_velocity *= 1 - water_angular_drag

func handle_movement():
	# Get the boat's forward direction (Negative Z is usually forward in Godot)
	var forward_dir = -global_transform.basis.z
	
	if !right_paddle_node: return
	if !left_paddle_node: return
	
	# To turn Right ('D'), we paddle on the LEFT side.
	var force_vector = forward_dir * paddle_force
	if Input.is_action_pressed("move_right"):
		var force_position = left_paddle_node.global_position - global_position
		apply_force(force_vector, force_position)
		right_paddle_animation.play("paddle", -1, 0.6)
	elif Input.is_action_pressed("move_back_right"):
		var force_position = left_paddle_node.global_position - global_position
		apply_force(-force_vector, force_position)
		right_paddle_animation.play("paddle", -1, -0.6, true)
	else:
		right_paddle_animation.stop()
		
	# To turn Left ('A'), we paddle on the RIGHT side.
	if Input.is_action_pressed("move_left"):
		var force_position = right_paddle_node.global_position - global_position
		apply_force(force_vector, force_position)
		left_paddle_animation.play("paddle", -1, 0.6)
	elif Input.is_action_pressed("move_back_left"):
		var force_position = right_paddle_node.global_position - global_position
		apply_force(-force_vector, force_position)
		left_paddle_animation.play("paddle", -1, -0.6, true)
	else:
		left_paddle_animation.stop()
