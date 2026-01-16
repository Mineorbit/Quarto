extends Node3D

@onready var card_field_label = preload("res://card/CardFieldLabel.tscn")
@onready var card_field_value = preload("res://card/CardFieldValue.tscn")
@onready var card_name_label = $SubViewport/CardInformation/Name
@onready var card_stats = $SubViewport/CardInformation/Stats/GridContainer

var card_values = {}

func initialize_card(card_name,card_values):
	card_name_label.text = card_name
	self.card_values = card_values
	for item in card_values:
		var card_stat_label = card_field_label.instantiate()
		card_stat_label.text = str(item)
		card_stats.add_child(card_stat_label)
		var card_stat_value = card_field_value.instantiate()
		card_stat_value.text = str(card_values[item])
		card_stats.add_child(card_stat_value)
