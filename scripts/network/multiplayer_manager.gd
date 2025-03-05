class_name MultiplayerManager
extends Node

# The bulk of this script is for the authority (host/server).

@export var _player_spawn_point: Node3D

var _multiplayer_scene = preload("res://scenes/player/player.tscn")
var _players_in_game: Dictionary = {}

func _ready():
	# NOTE: For client peers, this must run after we have an active connection.
	# By the time this runs on a client peer, the authority (server) side has already been
	# executed, so you cannot rely on it for running any authority-side logic. Of course
	# you can send an RPC to the authority side if necessary to setup something on the authority.
	
	# need this to allow time for the callbacks to be established
	await get_tree().process_frame
	print("MultiplayerManager ready!")

	if is_multiplayer_authority():
		# Handle the disconnect signal here so we have access to what needs cleaned up in game.
		multiplayer.peer_disconnected.connect(_client_disconnected)
		
		if NetworkManager.is_hosting_game && not OS.has_feature("dedicated_server"):
			print("Adding Host player to game...")
			_add_player_to_game(1)

	else:
		# Ask the authority to spawn our player once this loads on the client.
		# Since this node is loaded after a connection has been confirmed (as part of game scene),
		# tell the authority that our client is ready to spawn in the player. Should eliminate any race
		# conditions that may have arised by relying on server side "client connected" signals to 
		# spawn in players.
		_client_ready_for_player_spawn_rpc.rpc_id(1)
		
# Once the game scene is loaded on the client, use this to spawn in player.
# Call_remote as we don't want to hit this locally. 
# Reliable because we want to make sure it happens.
@rpc("any_peer", "call_remote", "reliable")
func _client_ready_for_player_spawn_rpc():
	if is_multiplayer_authority():
		_add_player_to_game(multiplayer.get_remote_sender_id())

func _add_player_to_game(network_id: int):
	if is_multiplayer_authority():
		print("Adding player to game: %s" % network_id)
		
		if _players_in_game.get(network_id) == null:
			var player_to_add = _multiplayer_scene.instantiate()
			player_to_add.name = str(network_id)
			_ready_player(player_to_add)
			
			_players_in_game[network_id] = player_to_add
			_player_spawn_point.add_child(player_to_add)
		else:
			print("Warning! Attempted to add existing player to game: %s" % network_id)
	
func _remove_player_from_game(network_id: int):
	if is_multiplayer_authority():
		print("Removing player from game: %s" % network_id)
		if _players_in_game.has(network_id):
			var player_to_remove = _players_in_game[network_id]
			if player_to_remove:
				player_to_remove.queue_free()		
				_players_in_game.erase(network_id)

# Setup initial or reload saved player properties
func _ready_player(player: Player):
	if is_multiplayer_authority():
		player.position = Vector3(randi_range(-2, 2), 1, randi_range(-2, 2))

func _client_disconnected(network_id: int):
	print("Client disconnected %s" % network_id)
	_remove_player_from_game(network_id)
