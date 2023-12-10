class_name xr_unit
extends unit

var hmd : XRCamera3D

var input_dir : Vector2

var left_hand_transform : Transform3D
var rigt_hand_transform : Transform3D
var head_transform : Transform3D



var head_offset : Vector3
var head_compensation_velocity : Vector3

signal input_direction_changed
signal head_transform_changed
signal left_hand_transform_changed
signal right_hand_transform_changed


func grab_left():
	pass

func drop_left():
	pass


func grab_rigt(): 
	pass

func drop_rigt():
	pass


func use_left(): # trigger
	pass


func use_rigt(): # trigger
	pass


func set_left_hand_transform(tra : Transform3D, is_override = false):
	left_hand_transform = tra
	if !is_override:
		left_hand_transform_changed.emit()


func set_rigt_hand_transform(tra : Transform3D, is_override = false):
	rigt_hand_transform = tra
	if !is_override:
		right_hand_transform_changed.emit()


func set_walk_vector(vec : Vector2, is_override = false):
	input_dir = vec.normalized() * min (vec.length(), 1.0)
	if !is_override:
		input_direction_changed.emit()


func set_head_transform(tra : Transform3D, is_override = false):
	head_transform = tra
	if !is_override:
		head_transform_changed.emit()


func set_hmd_ref(node : XRCamera3D):
	hmd = node
