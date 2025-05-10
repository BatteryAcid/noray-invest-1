extends Control

const NORAY_CLIENT_PLACEHOLDER_TEXT = "Enter Host's Game ID"
const NORAY_HOSTING_LABEL = "Host Game with Noray!"
const NORAY_CLIENT_CONNECT_LABEL = "Connect to game on Noray!"

@export var go_button: Button
@export var back_button: Button
@export var host_ip_input: LineEdit
@export var game_id_input: LineEdit
@export var option_label: RichTextLabel

signal secondary_menu_completed
signal secondary_menu_cancelled

var menu_config_options: Dictionary = {}
var _is_hosting: bool = false

func _ready():
	game_id_input.placeholder_text = NORAY_CLIENT_PLACEHOLDER_TEXT
	game_id_input.text = ""
	
	if menu_config_options.has("is_hosting") && menu_config_options.get("is_hosting") == true:
		_is_hosting = true
		
	if _is_hosting:
		option_label.text = NORAY_HOSTING_LABEL
		game_id_input.visible = false
	else:
		option_label.text = NORAY_CLIENT_CONNECT_LABEL
		game_id_input.visible = true

func _on_go_pressed():
	print("On Go pressed")
	if _is_hosting:
		# Host IP is required to host Noray game
		if host_ip_input.text && host_ip_input.text != "":
			var network_connection_configs = NetworkConnectionConfigs.new(host_ip_input.text)
			secondary_menu_completed.emit(network_connection_configs)
	else:
		# Host IP AND Game ID are both required for joining as client to Noray
		if host_ip_input.text && host_ip_input.text != "" && game_id_input.text && game_id_input.text != "":
			var network_connection_configs = NetworkConnectionConfigs.new(host_ip_input.text)
			network_connection_configs.game_id = game_id_input.text
			secondary_menu_completed.emit(network_connection_configs)

func _on_back_pressed():
	print("On Back pressed")
	secondary_menu_cancelled.emit()
