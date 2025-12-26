extends Node

@onready var cards = $World/cards
@onready var CardTemplate = preload("res://card/Card.tscn")


func load_cardpack(path):
	print("Loading Cardpack: "+path)
	var files = DirAccess.get_files_at("user://card_packs/"+path)
	for file in files:
		print(file)
		var card = CardTemplate.instantiate()
		cards.add_child(card)

func _ready():
	load_cardpack("Testpack")
