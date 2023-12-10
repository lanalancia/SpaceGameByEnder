class_name player_controller_xr
extends Node

"""

"""

@onready var debug_nodes = [
	$XROrigin3D/XRLeft/ButtonVisualizer,
	$XROrigin3D/XRRigt/ButtonVisualizer,
	$XROrigin3D/XRRigt/debug_wrist_speed
]

@onready var HMD = $XROrigin3D/XRCamera3D
@onready var lhand = $XROrigin3D/XRLeft
@onready var rhand = $XROrigin3D/XRRigt

@onready var lglove = $XROrigin3D/XRLeft/left_hand/Armature_001/Skeleton3D/vr_glove_left_slim
@onready var rglove = $XROrigin3D/XRRigt/right_hand/Armature/Skeleton3D/vr_glove_right_slim

@onready var oxr_left = $XROrigin3D/OpenXRHandL
@onready var oxr_rigt = $XROrigin3D/OpenXRHandR

@export var debug_mode : bool = false

var puppet : xr_unit

var destination : Vector3
var prev_hmd_pos : Vector3
var prev_lhand_pos : Vector3
var prev_rhand_pos : Vector3
var left_hand_shift : Vector3
var rigt_hand_shift : Vector3

var left_airpull : Vector3
var rigt_airpull : Vector3

var output_dir = Vector2.ZERO

var xr_interface: XRInterface

func _ready():
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR initialised successfully")
		# Turn off v-sync!
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		# Change our main viewport to output to the HMD
		get_viewport().use_xr = true
	else:
		print("OpenXR not initialized, please check if your headset is connected")
	
	for i in debug_nodes:
		i.visible = debug_mode
	
	puppet = get_parent()
	puppet.get_lhand().set_skeleton_ref($XROrigin3D/XRLeft/left_hand/Armature_001/Skeleton3D)
	puppet.get_rhand().set_skeleton_ref($XROrigin3D/XRRigt/right_hand/Armature/Skeleton3D)
	puppet.set_hmd_ref(HMD)
	puppet.input_direction_changed.connect(_on_dir_event_override)
	$XROrigin3D.global_position = puppet.global_position


func _physics_process(delta):
	compenstate_body(delta)
	compensate_hmd_raw(delta)


func _process(delta):
	puppet.set_left_hand_transform(lhand.transform)
	puppet.set_rigt_hand_transform(rhand.transform)
	puppet.set_head_transform(HMD.transform)
	
	output_dir = lhand.get_vector2("primary").rotated(HMD.rotation.y)
	puppet.rotate_y(-rhand.get_vector2("primary").x * delta * 4.0)
	
	
	update_glove_transparency()
	
	sprint_puppet(delta)
	calculate_by_shift()
	by_shift_puppet(delta)
	fill_prevs()
	puppet.set_walk_vector(output_dir)
	
	#$XROrigin3D/XRRigt/debug_offset.text = str(int(puppet.height_offset*100))
	#$XROrigin3D/XRRigt/debug_height.text = str(int(puppet.current_height*100))
	
	


func sprint_puppet(delta):
	var sprint_limit = delta * 0.65
	
	var llen = (lhand.position - prev_lhand_pos) * Vector3(0.0, 1, 0.0)
	var rlen = (rhand.position - prev_rhand_pos) * Vector3(0.0, 1, 0.0)
	
	var left_sprint = min(llen.length(), sprint_limit) / sprint_limit
	var rigt_sprint = min(rlen.length(), sprint_limit) / sprint_limit
	
	puppet.set_sprint_value(max(left_sprint, rigt_sprint))


func update_glove_transparency():
	var l_dist = puppet.get_lhand().global_position - lhand.global_position
	lglove.transparency = clamp(1-((l_dist.length() - 0.13) / 0.13), 0, 1)
	var r_dist = puppet.get_rhand().global_position - rhand.global_position
	rglove.transparency = clamp(1-((r_dist.length() - 0.13) / 0.13), 0, 1)


func _on_dir_event_override():
	# ну, предположим, ничего не делает
	pass

func by_shift_puppet(delta):
	var lby = lhand.is_button_pressed("by_button")
	var rby = rhand.is_button_pressed("by_button")
	
	if !lby and !rby:
		return
	
	var vec_sum = (left_hand_shift + rigt_hand_shift)
	
	# для вектора движения
	#if (lby and !rby) or (!lby and rby): 
	var vec_lim = vec_sum.normalized() * min(vec_sum.length(), 1) * 60#*(1/delta)
	output_dir += (Vector2(-vec_lim.x, vec_lim.z)).rotated(HMD.rotation.y)
	#puppet.add_height_offset((-vec_lim.y / (1 * delta))*0.00009)
	puppet.add_height_offset(-vec_lim.y * 1.7 * delta)
	
	# Для доджей
	if rby and lby: 
		if vec_sum.length() > 1:
			pass
			# TODO если достигнута нужная длина - делать уворот, иначе не делать
		
		pass


func calculate_by_shift():
	var lby = lhand.is_button_pressed("by_button")
	var rby = rhand.is_button_pressed("by_button")
	
	if lby:
		left_hand_shift = lhand.position - prev_lhand_pos
	else:
		left_hand_shift = Vector3.ZERO
	
	if rby:
		rigt_hand_shift = rhand.position - prev_rhand_pos
	else:
		rigt_hand_shift = Vector3.ZERO



func grab_left():
	puppet.grab_left()

func drop_left():
	puppet.drop_left()


func grab_rigt(): 
	puppet.grab_rigt()

func drop_rigt():
	puppet.drop_rigt()


func use_left(): # trigger
	pass


func use_rigt(): # trigger
	pass


func compenstate_body(delta):
	var delta_pos = -(puppet.global_position - HMD.global_position)
	var push_to_head = Vector3()
	var linear_force = 120.0
	var linear_stiffness = 0.7
	
	push_to_head += (delta_pos * linear_force) - (puppet.velocity * linear_stiffness)
	puppet.head_compensation_velocity = push_to_head * Vector3(1, 0, 1)


func compensate_hmd(delta):
	var delta_pos = puppet.global_position - $SmoothHelper.global_position 
	$SmoothHelper.global_position += delta_pos * Vector3(1, 0, 1) * 0.9
	$SmoothHelper.global_position.y = puppet.global_position.y + puppet.get_offset_for_xr().y
	$SmoothHelper.rotation.y = puppet.rotation.y


func compensate_hmd_raw(delta):
	var delta_pos = puppet.global_position - HMD.global_position 
	$XROrigin3D.global_position += delta_pos * Vector3(1, 0, 1) * 40 * delta
	$XROrigin3D.global_position.y = puppet.global_position.y + puppet.get_offset_for_xr().y
	$XROrigin3D.rotation.y = puppet.rotation.y


func fill_prevs():
	prev_hmd_pos = HMD.position
	prev_lhand_pos = lhand.position
	prev_rhand_pos = rhand.position


func _on_xr_left_button_pressed(name):
	match name:
		"grip_click":
			grab_left()


func _on_xr_left_button_released(name):
	match name:
		"grip_click":
			drop_left()


func _on_xr_rigt_button_pressed(name):
	match name:
		"grip_click":
			grab_rigt()


func _on_xr_rigt_button_released(name):
	match name:
		"grip_click":
			drop_rigt()
