extends Control

const GAME_SCENE = "res://scenes/game.tscn"
const NORAY_CLIENT_PLACEHOLDER_TEXT = "Enter Host's Game ID"
const ENET_CLIENT_PLACEHOLDER_TEXT = "Enter Host's IP"
const DEFAULT_LOCALHOST_IP = "127.0.0.1"

@export var host_game_button: Button
@export var join_game_button: Button
@export var go_button: Button
@export var back_button: Button
@export var host_ip_input: LineEdit
@export var game_id_input: LineEdit # Can also be IP for non-noray setups
@export var noray_option_label: RichTextLabel

var _host_selected = false

func _ready():
	print("Main menu ready...")
	if OS.has_feature("dedicated_server"):
		print("Calling host game...")
		NetworkManager.host_game("") # Running ENet dedicated server doesn't require an IP
		get_tree().call_deferred(&"change_scene_to_packed", preload(GAME_SCENE))

func host_game():
	print("Host game pressed")
	if NetworkManager.selected_network == NetworkManager.AvailableNetworks.NORAY:
		_show_host_noray_options()
	else:
		NetworkManager.host_game("") # Running ENet server doesn't require an IP
		get_tree().call_deferred(&"change_scene_to_packed", preload(GAME_SCENE))

# TODO: clean up
func _show_host_noray_options():
	noray_option_label.text = "Host Game with Noray!"
	_host_selected = true
	host_game_button.visible = false
	join_game_button.visible = false
	host_ip_input.visible = true
	game_id_input.visible = false
	go_button.visible = true
	back_button.visible = true

func _show_client_noray_options():
	noray_option_label.text = "Connect to game on Noray!"
	_host_selected = false
	host_game_button.visible = false
	join_game_button.visible = false
	host_ip_input.visible = true
	game_id_input.visible = true
	go_button.visible = true
	back_button.visible = true

func _reset_noray_options():
	noray_option_label.text = ""
	host_game_button.visible = true
	join_game_button.visible = true
	host_ip_input.visible = false
	game_id_input.visible = false
	go_button.visible = false
	back_button.visible = false

func join_game():
	print("Join game pressed %s" % game_id_input.text)
	# NOTE: The game_id can represent both the ip to connect to or the host's game ID
	
	if NetworkManager.selected_network == NetworkManager.AvailableNetworks.NORAY:
		_show_client_noray_options()
			
	elif game_id_input.text && game_id_input.text != "":
		# Here we use Game ID to represent the host IP to connect to
		NetworkManager.join_game(game_id_input.text, "") # Game ID not required for ENet
		get_tree().call_deferred(&"change_scene_to_packed", preload(GAME_SCENE))
	
func _on_noray_button_toggled(toggled_on):
	print("Noray enabled %s" % toggled_on)
	#host_ip_input.visible = toggled_on
	NetworkManager.noray_enabled(toggled_on)
	
	if toggled_on:
		game_id_input.placeholder_text = NORAY_CLIENT_PLACEHOLDER_TEXT
		game_id_input.text = ""
	else:
		game_id_input.placeholder_text = ENET_CLIENT_PLACEHOLDER_TEXT
		game_id_input.text = DEFAULT_LOCALHOST_IP

func _on_go_pressed():
	print("On Go pressed")
	if _host_selected:
		# Host IP is required to host Noray game
		if host_ip_input.text && host_ip_input.text != "":
			NetworkManager.host_game(host_ip_input.text)
			get_tree().call_deferred(&"change_scene_to_packed", preload(GAME_SCENE))
	else:
		# Host IP AND Game ID are both required for joining as client to Noray
		if host_ip_input.text && host_ip_input.text != "" && game_id_input.text && game_id_input.text != "":
			NetworkManager.join_game(host_ip_input.text, game_id_input.text)
			get_tree().call_deferred(&"change_scene_to_packed", preload(GAME_SCENE))

func _on_back_pressed():
	print("On Back pressed")
	_reset_noray_options()

func exit_game():
	get_tree().quit(0)
