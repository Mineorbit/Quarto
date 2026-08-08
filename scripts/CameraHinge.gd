extends Node3D

var target_rotation: Quaternion
var t: float

@onready var old_rotation: Quaternion = self.quaternion
@onready var target_hinge_position = get_child(0).position

func update_rotation(new_rotation: Quaternion):
	old_rotation = target_rotation
	target_rotation = new_rotation
	t = 0

@rpc("any_peer", "call_local", "reliable")
func set_topdown_view():
	update_rotation(Quaternion.from_euler(Vector3(deg_to_rad(-60), deg_to_rad(-180), 0)))
	target_hinge_position = Vector3(0,1.6,2.5)

@rpc("any_peer", "call_local", "reliable")
func set_player_view(immediate:bool = false):
	var angle = 90 + Game.get_own_player_id()*(360/NetworkLobby.players.size())
	var rot = Quaternion.from_euler(Vector3(deg_to_rad(0), deg_to_rad(angle), 0))
	if immediate:
		old_rotation = rot
		target_rotation = rot
		quaternion = rot
	else:
		update_rotation(rot)
	target_hinge_position = 0.8*Vector3(0,3,5)

func _process(delta: float) -> void:
	t = clampf(t+2*delta,0,1)
	quaternion = old_rotation.slerp(target_rotation,t)
	get_child(0).position = get_child(0).position.lerp(target_hinge_position,0.01)
