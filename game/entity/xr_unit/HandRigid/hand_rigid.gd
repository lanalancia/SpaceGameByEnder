class_name xr_physical_hand
extends RigidBody3D

@onready var glove_l = $wrists/vr_glove_left_slim
@onready var glove_r = $wrists/vr_glove_right_slim
@export_enum("left", "right") var type = 0

@export var grabbable_marker : PackedScene
@export var collision_excluder : PackedScene

var master : Node3D
var grabbed_body : PhysicsBody3D
var grabbed_offset : Vector3

var other_hand : xr_physical_hand

func _ready():
	glove_l.hide()
	glove_r.hide()
	match type:
		0: 
			glove_l.show()
		1:
			glove_r.show()


func _process(delta):
	#visible = !is_holding_something()
	pass


func grab():
	if is_holding_something():
		drop()
	
	var candidates : Array = $Area3D.get_overlapping_bodies()
	var filtered = []
	for i in candidates:
		if !i is xr_physical_hand:
			filtered.append(i)
	
	if filtered.size() == 0:
		return
	
	var choosen = filtered.pick_random()
	$a_grab.node_a = $a_grab.get_path_to(choosen)
	grabbed_body = choosen
	var new_marker = grabbable_marker.instantiate()
	new_marker.set_hand(self)
	grabbed_body.add_child(new_marker)
	var new_excluder = collision_excluder.instantiate()
	new_excluder.set_hand(self)
	grabbed_body.add_child(new_excluder)


func drop():
	if !is_holding_something():
		return
	
	$a_grab.node_a = $a_grab.get_path_to(self)
	grabbed_body = null


func is_holding_something():
	return grabbed_body != null


func move_to_destination(destination_global_transform):
	var A = destination_global_transform
	var B = global_transform
	
	# translation
	var force_linear = 1450.0
	var stiffness_linear = 25.0
	var delta_pos = A.origin - B.origin 
	var velo_diff = linear_velocity - get_parent().get_parent().velocity
	#print(str(type), ":", velo_diff)
	var pos_value = (delta_pos * force_linear) - (velo_diff * stiffness_linear)
	
	if is_holding_something():
		pos_value /= max(grabbed_body.mass * 0.4, 1.0)
	
	pos_value = pos_value.normalized() * min( pos_value.length(), 200.0)
	
	apply_central_force(pos_value) #+ get_parent().get_parent().velocity * 0)
	
	# rotation
	var force_torque = 60.0
	var stiffness_torque = 0.95
	var eulers = (A.basis * B.basis.inverse()).get_euler()
	var rot_values = (eulers * force_torque) - (angular_velocity * stiffness_torque)
	
	if is_holding_something():
		if grabbed_body is RigidBody3D:
			rot_values *= 1.5
			#rot_values = rot_values * grabbed_body.mass * 0.01 + rot_values* mass
	
	
	angular_velocity += rot_values * get_physics_process_delta_time() * 60
	
	if is_holding_something():
		if grabbed_body is RigidBody3D:
			# TODO : 1) крутить, 2) толкнуть от места хвата к руке.
			# надо сохранять место хвата
			#grabbed_body.angular_velocity += rot_values * 0.1 * get_physics_process_delta_time() * 180- grabbed_body.angular_velocity * 0.5
			angular_velocity = lerp(angular_velocity, Vector3.ZERO, 0.1)
			grabbed_body.apply_central_force(pos_value * grabbed_body.mass *0.3)


func set_skeleton_ref(ref: Skeleton3D):
	glove_l.set_skeleton_path( glove_l.get_path_to(ref) )
	glove_r.set_skeleton_path( glove_r.get_path_to(ref) )


func set_master_ref(ref):
	master = ref
