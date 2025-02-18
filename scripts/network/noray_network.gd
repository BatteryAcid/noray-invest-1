extends Node

var host = "ec2-34-217-179-133.us-west-2.compute.amazonaws.com"
var port = 8890
var err = OK

func _ready():
	# TODO: right now this signal is only for client, the server one is in multiplayer_manager, refactor?
	Noray.on_connect_nat.connect(_handle_connect)

func create_server_peer():
	print("Create server peer, calling to register with Noray...")
	await _register_with_noray()
	print("Calling to start Noray host...")
	_start_noray_host()

func _register_with_noray():
	print("Register with Noray...")
	
	# Connect to noray
	err = await Noray.connect_to_host(host, port)
	if err != OK:
		print("Failed to connect %s" % err)
		return err # Failed to connect

	# Register host
	Noray.register_host()
	await Noray.on_pid

	# Register remote address
	# This is where noray will direct traffic
	err = await Noray.register_remote()
	if err != OK:
		print("Failed to register %s" % err)
		return err # Failed to register
	
	print("Finished Noray registration")
	#_start_noray_host()

func _start_noray_host():
	print("Starting Noray host...")
	var noray_network_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	noray_network_peer.create_server(Noray.local_port)
	multiplayer.multiplayer_peer = noray_network_peer # TODO: is this line required?
	
	if err != OK:
		print("Failed to listen on port %s" % err)
		return false # Failed to listen on port

func create_client_peer(hosts_oid):
	print("Create client peer, calling to register with Noray...")
	await _register_with_noray()
	
	print("Create client peer for Noray through NAT with OID: %s" % hosts_oid)
	# Connect using NAT punchthrough
	Noray.connect_nat(hosts_oid)
	
	# Not supporting relay...

func _handle_connect(address: String, port: int) -> Error:
	print("Client handle connect to %s:%s" % [address, port])
	#print("networkid: %s" % multiplayer.get_unique_id())
	
 	# Do a handshake
	var udp = PacketPeerUDP.new()
	udp.bind(Noray.local_port)
	udp.set_dest_address(address, port)

	var err = await PacketHandshake.over_packet_peer(udp)
	udp.close()

	if err != OK:
		print("Client packet handshake failure %s" % err)
		return err

	# Connect to host
	var peer = ENetMultiplayerPeer.new()
	err = peer.create_client(address, port, 0, 0, 0, Noray.local_port)

	if err != OK:
		print("Create client failure failure %s" % err)
		return err

	return OK
