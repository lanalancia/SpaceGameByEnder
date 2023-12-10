extends xr_unit

@onready var rhand = $Hands/HandRigidR
@onready var lhand = $Hands/HandRigidL
@onready var lh = $lhelper
@onready var rh = $rhelper
@onready var collision_shapes = [
	$CollisionCapsuleTop, 
	$CollisionCylinder1, 
	$CollisionCylinder2, 
	$CollisionCylinder3, 
	$CollisionCylinder4, 
	$CollisionCapsuleBot
]


const SPEED = 6.0
const SPRINT_SPEED = 14.0
const collision_heights = [0.3, 0.6, 0.9, 1.2, 1.5, 1.8]

var sprint_value = 1.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var l_tra : Transform3D
var r_tra : Transform3D

var current_height = 1.0
var height_offset = 0

func _ready():
	add_collision_exception_with(rhand)
	add_collision_exception_with(lhand)


func _physics_process(delta):
	update_collision()
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	#sprint_value = 1.0
	var direction = (get_head().global_transform.basis * Vector3(input_dir.x, 0, -input_dir.y))
	if direction:
		velocity.x = direction.x * SPEED + (direction.x * SPRINT_SPEED * sprint_value)
		velocity.z = direction.z * SPEED + (direction.z * SPRINT_SPEED * sprint_value)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	calculate_hands_push(delta)
	velocity += head_compensation_velocity
	move_and_slide()
	
	place_head()
	place_left_hand()
	place_rigt_hand()


func place_head():
	$head.position = head_transform.origin


func place_left_hand():
	lh.transform.basis = left_hand_transform.basis
	lh.position = lh.position.lerp(left_hand_transform.origin, 0.2)
	var head_pos_rotated : Vector3 = get_head().position
	head_pos_rotated = head_pos_rotated.rotated(Vector3.UP, global_rotation.y)
	var composed_left_transform = lh.global_transform
	composed_left_transform.origin = lh.global_position - (head_pos_rotated * Vector3(1, 0, 1))
	composed_left_transform.origin.y += get_offset_for_xr().y
	composed_left_transform.origin -= velocity * 0.025
	lhand.move_to_destination(composed_left_transform)


func place_rigt_hand():
	rh.transform.basis = rigt_hand_transform.basis
	rh.position = rh.position.lerp(rigt_hand_transform.origin, 0.2)
	var head_pos_rotated : Vector3 = get_head().position
	head_pos_rotated = head_pos_rotated.rotated(Vector3.UP, global_rotation.y)
	var composed_rigt_transform = rh.global_transform
	composed_rigt_transform.origin = rh.global_position - (head_pos_rotated * Vector3(1, 0, 1))
	composed_rigt_transform.origin.y += get_offset_for_xr().y
	composed_rigt_transform.origin -= velocity * 0.025
	rhand.move_to_destination(composed_rigt_transform)


func add_height_offset(value):
	height_offset += value
	height_offset = clamp(height_offset, -1.0, 1.0)


func set_sprint_value(value):
	value = lerp(value, sprint_value, 0.8)
	sprint_value = clamp(value, 0, 1)


func update_collision():
	current_height = ($head.position.y - 0.15) / 1.8
	current_height = clamp(current_height, 0, 1.0)
	
	height_offset = clamp(height_offset, 0.0-current_height, 1.0-current_height)
	
	var c = 0
	for i in collision_shapes as Array[CollisionShape3D]:
		i.position.y = lerp(0.3, collision_heights[c], clamp(current_height+height_offset, 0, 1.0))
		c += 1


func calculate_hands_push(delta):
	var offset = Vector3(get_head().position.x, -get_offset_for_xr().y, get_head().position.z)
	offset = offset.rotated(Vector3.UP, get_head().global_rotation.y)
	
	var delta_left = lhand.global_position - lh.global_position + offset
	var delta_rigt = rhand.global_position - rh.global_position + offset
	
	
	
	var push_power = 5
	var left_dist = delta_left.length()
	if left_dist > 0.1:
		var elevate_l = delta_left.y
		delta_left.y = 0
		velocity += delta_left.normalized() * Vector3(1, 0, 1) * push_power * (delta_left.length() - 0.1)
		height_offset += move_toward(elevate_l, 0, 0.1) * 10 * delta
	
	var rigt_dist = delta_rigt.length()
	if rigt_dist > 0.1:
		var elevate_r = delta_rigt.y
		delta_left.y = 0
		velocity += delta_rigt.normalized() * Vector3(1, 0, 1) * push_power * (delta_rigt.length() - 0.1)
		height_offset += move_toward(elevate_r, 0, 0.1) * 10 * delta


func get_head():
	return $head

func get_lhand():
	return $Hands/HandRigidL

func get_rhand():
	return $Hands/HandRigidR


func get_offset_for_xr():
	var ret = $head.position
	ret.y -= ret.y * (1-height_offset)
	return ret


func grab_left():
	lhand.grab()
	pass

func drop_left():
	lhand.drop()
	pass


func grab_rigt(): 
	rhand.grab()
	pass

func drop_rigt():
	rhand.drop()
	pass











