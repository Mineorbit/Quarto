extends Node3D

@export var cardHook: Node3D

var card_spacing = 0.065


var target_position: Vector3

func get_players_card_value(feature):
	var top_card = get_top_card()
	if top_card !=  null && top_card.card_values.has(feature):
		return top_card.card_values[feature]
	else:
		return 0


func place_card_in_hand(card,front=true):
	print("Placing Card \""+card.plain_card_name+"\" in Player "+str(name)+"'s Hand")
	card.request_reparent(cardHook,front)
	align_cards_in_hand()

func align_cards_in_hand():
	var i = 0
	for c in cardHook.get_children():
		c.target_position = Vector3.ZERO
		c.rotation = cardHook.rotation
		c.target_position = (Vector3.FORWARD+Vector3.RIGHT*2.5)*i*card_spacing
		i = i + 1

func get_top_card():
	if cardHook.get_child_count() > 0:
		return cardHook.get_child(-1)
	else:
		return null

var radius = 2
func position_of_player_hand(i):
		# 1. Calculate the angle for this player
		var angle = (float(i) / float(NetworkLobby.players.size())) * 2.0 * PI
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		return Vector3(x, 0, z)

var eps = 0.0001

var morph_strength = 0.8

func _process(delta: float) -> void:
	if multiplayer.is_server():
		if (position - target_position).length_squared() > eps:
			position = morph_strength*position + (1-morph_strength)*target_position
		else:
			position = target_position
