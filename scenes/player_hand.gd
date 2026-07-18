extends Node3D

@export var cardHook: Node3D

func get_players_card_value(feature):
	var top_card = get_top_card()
	if top_card !=  null && top_card.card_values.has(feature):
		top_card.card_values[feature]
	else:
		return 0

func place_card_in_hand(card):
	print("Placing Card in Player's Hand")
	card.reparent(cardHook)
	card.position = Vector3.ZERO
	card.look_at(card.position + cardHook.global_transform.basis.z + Vector3.UP,Vector3.UP)

func get_top_card():
	if cardHook.get_child_count() > 0:
		return cardHook.get_child(0)
	else:
		return null
