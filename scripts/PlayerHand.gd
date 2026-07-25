extends Node3D

@export var cardHook: Node3D

var card_spacing = 0.065

func get_players_card_value(feature):
	var top_card = get_top_card()
	if top_card !=  null && top_card.card_values.has(feature):
		top_card.card_values[feature]
	else:
		return 0


func place_card_in_hand(card):
	print("Placing Card in Player's Hand")
	card.request_reparent(cardHook)
	card.position = Vector3.ZERO
	card.rotation = cardHook.rotation
	card.position = (Vector3.FORWARD+Vector3.RIGHT)*cardHook.get_child_count()*card_spacing

func get_top_card():
	if cardHook.get_child_count() > 0:
		return cardHook.get_child(0)
	else:
		return null

var radius = 2
func position_of_player_hand(i):
		# 1. Calculate the angle for this player
		var angle = (float(i) / float(NetworkLobby.players.size())) * 2.0 * PI
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		return Vector3(x, 0, z)
