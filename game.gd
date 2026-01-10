extends Node

@onready var cards = $World/cards
@onready var CardTemplate = preload("res://card/Card.tscn")

enum {UP,DOWN}

func load_cardpack(path):
	print("Loading Cardpack: "+path)
	var meta_file = FileAccess.open("user://card_packs/"+path+"/meta.txt", FileAccess.READ)
	var cardset_name = meta_file.get_line()
	print("Cardset: "+cardset_name)
	var number_cards = int(meta_file.get_line())
	print("Number of Cards: "+str(number_cards))
	var card_fields = []
	while not meta_file.eof_reached():
		var card_field_line = meta_file.get_line()
		var card_field_data = card_field_line.split(",")
		card_fields.append(card_field_data)
	print("Card Rules: "+str(card_fields))
	var game_cards = []
	for card_id in range(number_cards):
		print(card_id)
		var card_file = FileAccess.open("user://card_packs/"+path+"/"+str(card_id)+".txt",FileAccess.READ)
		var card = CardTemplate.instantiate()
		card.name = str(card_id)
		var card_name = card_file.get_line()
		cards.add_child(card)
		card.initialize_card(card_name,{"White":20,"Red":30})
		card.position = Vector3(card_id,card_id*0.25,0)
		game_cards.append(card)

func _ready():
	load_cardpack("Testpack")
