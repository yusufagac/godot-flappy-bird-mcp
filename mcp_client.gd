extends Node
class_name MCPClient

signal command_flap
signal command_restart
signal command_pause
signal command_resume

var socket: WebSocketPeer = WebSocketPeer.new()
var is_connected_to_server: bool = false
var reconnect_timer: float = 0.0
const RECONNECT_DELAY: float = 3.0
const SERVER_URL: String = "ws://localhost:8765"

func _ready() -> void:
	print("MCP Client starting connection to ", SERVER_URL)
	_connect_to_mcp_server()

func _connect_to_mcp_server() -> void:
	socket.connect_to_url(SERVER_URL)
	is_connected_to_server = false
	print("Connecting to MCP Server...")

func _process(delta: float) -> void:
	socket.poll()
	var state = socket.get_ready_state()
	
	if state == WebSocketPeer.STATE_OPEN:
		if not is_connected_to_server:
			is_connected_to_server = true
			print("Connected to MCP Server successfully!")
			_send_handshake()
		
		# Read packets
		while socket.get_available_packet_count() > 0:
			var packet = socket.get_packet()
			var packet_str = packet.get_string_from_utf8()
			_handle_server_message(packet_str)
			
	elif state == WebSocketPeer.STATE_CLOSED or state == WebSocketPeer.STATE_CLOSING:
		if is_connected_to_server:
			is_connected_to_server = false
			print("Disconnected from MCP Server.")
		
		if state == WebSocketPeer.STATE_CLOSED:
			reconnect_timer += delta
			if reconnect_timer >= RECONNECT_DELAY:
				reconnect_timer = 0.0
				_connect_to_mcp_server()

func _send_handshake() -> void:
	var handshake = {
		"type": "handshake",
		"client": "godot_flappy_bird"
	}
	send_payload(handshake)

func send_payload(payload: Dictionary) -> void:
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var json_str = JSON.stringify(payload)
		socket.send_text(json_str)

func _handle_server_message(message_str: String) -> void:
	var json = JSON.new()
	var error = json.parse(message_str)
	if error == OK:
		var data = json.get_data()
		if typeof(data) == TYPE_DICTIONARY:
			if data.has("command"):
				var cmd = data["command"]
				print("Received remote command: ", cmd)
				match cmd:
					"flap":
						command_flap.emit()
					"restart":
						command_restart.emit()
					"pause":
						command_pause.emit()
					"resume":
						command_resume.emit()
	else:
		print("JSON Parse Error: ", json.get_error_message())
