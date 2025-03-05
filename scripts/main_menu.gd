extends Control

@export var host_game_button: Button
@export var join_game_button: Button
@export var toggle_secondary_network_checkbutton: CheckButton
@export var secondary_network_menu_parent: Control

var _is_hosting = false

func _ready():
	print("Main menu ready...")

	if OS.has_feature("dedicated_server"):
		print("Calling host game for dedicated server setup...")
		NetworkManager.host_game()

func host_game():
	print("Host game pressed")
	_is_hosting = true
	
	# Has a secondary network option been selected for host
	if NetworkManager.selected_network != NetworkManager.AvailableNetworks.ENET:
		_show_secondary_network_options(true)
	else:
		NetworkManager.host_game()

func join_game():
	_show_secondary_network_options()

func _show_secondary_network_options(is_hosting: bool = false):
	_hide_main_menu_options()
	
	var second_menu_to_load = load(NetworkManager.selected_network_configuration.menu)
	var active_secondary_menu = second_menu_to_load.instantiate()
	
	# Add whatever necessary configuration is required in the sub menu
	if _is_hosting:
		active_secondary_menu.menu_config_options = { "is_hosting": is_hosting }
		
	secondary_network_menu_parent.add_child(active_secondary_menu)
	
	# Wire up completed and cancelled secondary menu signals
	active_secondary_menu.secondary_menu_completed.connect(_secondary_menu_submitted)
	active_secondary_menu.secondary_menu_cancelled.connect(_cancel_secondary_menu)

func _secondary_menu_submitted(host_ip: String = "", host_port: String = "", game_id: String = ""):
	if _is_hosting:
		NetworkManager.host_game(host_ip)
	else:
		NetworkManager.join_game(host_ip, host_port, game_id)

# NOTE: for now just use a toggle, but if you had another network type you wanted to support,
# like Steam, we'd have to think of a different UI selection mechanism.
func _on_noray_button_toggled(noray_enabled):
	print("Noray enabled %s" % noray_enabled)
	
	if noray_enabled:
		NetworkManager.set_selected_network(NetworkManager.AvailableNetworks.NORAY)
	else:
		NetworkManager.set_selected_network(NetworkManager.AvailableNetworks.ENET)

func _reset_main_menu_options():
	_is_hosting = false
	host_game_button.visible = true
	join_game_button.visible = true
	toggle_secondary_network_checkbutton.visible = true
	toggle_secondary_network_checkbutton.set_pressed_no_signal(false) # reset secondary selection
	NetworkManager.reset_selected_network()

func _hide_main_menu_options():
	host_game_button.visible = false
	join_game_button.visible = false
	toggle_secondary_network_checkbutton.visible = false

func _cancel_secondary_menu():
	_reset_main_menu_options()
	# Remove secondary menu
	secondary_network_menu_parent.get_children()[0].queue_free()

func exit_game():
	get_tree().quit(0)
