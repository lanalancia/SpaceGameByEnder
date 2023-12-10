extends Node


var owner_hand: xr_physical_hand
var death_timer = 1.0

var is_alive = true

func _ready():
	if !get_parent() is RigidBody3D:
		queue_free()
		return
	

func _physics_process(delta):
	get_parent().add_collision_exception_with(owner_hand)
	if owner_hand.grabbed_body != get_parent():
		death_timer -= delta * 2.0
	
	if death_timer <= 0:
		get_parent().remove_collision_exception_with(owner_hand)
		queue_free()


func set_hand(ref):
	owner_hand = ref
