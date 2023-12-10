extends Node


var owner_hand: xr_physical_hand

const GRAVITY_OVERRIDE = 0.8

func _ready():
	if !get_parent() is RigidBody3D:
		queue_free()
		return


func _physics_process(delta):
	if owner_hand.grabbed_body != get_parent():
		get_parent().gravity_scale = 1.0
		queue_free()
		return
	
	get_parent().gravity_scale = GRAVITY_OVERRIDE


func set_hand(ref):
	owner_hand = ref

