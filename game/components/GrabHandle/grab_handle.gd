@tool
extends Node

@export var offset_pos: Vector3
@export var offset_rot: Vector3

@export var joint : JoltJoint3D

var is_grabbed = false

func _process(delta):
	if get_parent() is Node3D:
		$RigidRef.global_transform = get_parent().global_transform
	
	$RigidRef/GrabMarker.position = offset_pos
	$RigidRef/GrabMarker.rotation_degrees = offset_rot


func grab():
	if joint == null:
		return
	
	
	
	
	
	
	

