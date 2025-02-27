extends Node

func _ready() -> void:
	self.visible = false

func show():
	$Panel/IpPanel/IpLabel.text = NetworkManager.active_host_ip
	$Panel/GameIdPanel/GameIdPanel.text = NetworkManager.active_game_id
	
	self.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	

func hide():
	self.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("in-game-menu"):
		if (self.visible):
			hide()
		else:
			show()

func _on_resume_pressed() -> void:
	hide()

func _on_quit_pressed() -> void:
	get_tree().quit()

func copy_hostip_to_clipboard():
	DisplayServer.clipboard_set(NetworkManager.active_host_ip)

func copy_gameid_to_clipboard():
	DisplayServer.clipboard_set(NetworkManager.active_game_id)
