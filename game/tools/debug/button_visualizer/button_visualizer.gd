extends Node3D

@export var xr_button_name : String


func _process(delta):
	if !get_parent() is XRController3D:
		queue_free()
		print("A parent should be XR controller")
		return
	
	$on.visible = get_parent().is_button_pressed(xr_button_name)
