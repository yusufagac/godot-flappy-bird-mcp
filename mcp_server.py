import json
import asyncio
import threading
import websockets
from mcp.server.fastmcp import FastMCP

# Initialize FastMCP Server
mcp = FastMCP("GodotFlappyBird")

# Thread-safe global state variables
state_lock = threading.Lock()
latest_state = {
    "game_state": "DISCONNECTED",
    "score": 0,
    "highscore": 0,
    "bird_y": 0.0,
    "bird_vy": 0.0,
    "bird_alive": False,
    "next_pipe_x": -999.0,
    "next_pipe_top_y": -999.0,
    "next_pipe_bottom_y": -999.0,
    "ground_y": 640.0
}
active_websocket = None
autopilot_enabled = False

# Custom async helper to send commands over WebSocket in a thread-safe manner
def send_command_to_godot(command: str):
    global active_websocket
    if active_websocket is None:
        return "Error: No Godot client connected to the MCP server."
    
    payload = {"command": command}
    message = json.dumps(payload)
    
    # Run the coroutine in the background thread's loop safely
    asyncio.run_coroutine_threadsafe(
        active_websocket.send(message), 
        ws_event_loop
    )
    return f"Success: Dispatched command '{command}' to Godot."

# Autopilot Loop running inside the WebSocket thread
async def autopilot_loop():
    global autopilot_enabled, latest_state
    print("[Autopilot] Background monitoring loop started.")
    
    while True:
        await asyncio.sleep(0.05) # Check at 20Hz
        
        if not autopilot_enabled:
            continue
            
        with state_lock:
            game_state = latest_state.get("game_state", "DISCONNECTED")
            bird_y = latest_state.get("bird_y", 0.0)
            bird_alive = latest_state.get("bird_alive", False)
            next_pipe_top_y = latest_state.get("next_pipe_top_y", -999.0)
            next_pipe_bottom_y = latest_state.get("next_pipe_bottom_y", -999.0)
            
        # 1. If game over, trigger restart
        if game_state == "GAME_OVER":
            send_command_to_godot("restart")
            await asyncio.sleep(0.5) # Wait for level reset animation
            continue
            
        # 2. If at start screen, trigger first flap to start game
        if game_state == "START":
            send_command_to_godot("flap")
            await asyncio.sleep(0.2)
            continue
            
        # 3. Playing state: calculate target gap center and fly!
        if game_state == "PLAYING" and bird_alive:
            if next_pipe_top_y != -999.0 and next_pipe_bottom_y != -999.0:
                gap_center = (next_pipe_top_y + next_pipe_bottom_y) / 2.0
            else:
                gap_center = 320.0 # Default center if no pipe visible yet
                
            # If bird falls below the target gap center (+ offset), flap!
            if bird_y > gap_center + 10.0:
                send_command_to_godot("flap")

# WebSocket handler
async def ws_handler(websocket):
    global active_websocket, latest_state
    print("[WS] Godot game client connected!")
    active_websocket = websocket
    
    try:
        async for message in websocket:
            data = json.loads(message)
            if data.get("type") == "state":
                with state_lock:
                    latest_state = data
            elif data.get("type") == "handshake":
                print("[WS] Handshake received from Godot client.")
    except websockets.exceptions.ConnectionClosed:
        pass
    finally:
        print("[WS] Godot game client disconnected.")
        with state_lock:
            latest_state = {
                "game_state": "DISCONNECTED",
                "score": 0,
                "highscore": 0,
                "bird_y": 0.0,
                "bird_vy": 0.0,
                "bird_alive": False,
                "next_pipe_x": -999.0,
                "next_pipe_top_y": -999.0,
                "next_pipe_bottom_y": -999.0,
                "ground_y": 640.0
            }
        if active_websocket == websocket:
            active_websocket = None

# Background thread to run the WebSocket Server
ws_event_loop = None

def start_websocket_server():
    global ws_event_loop
    ws_event_loop = asyncio.new_event_loop()
    asyncio.set_event_loop(ws_event_loop)
    
    # Listen on localhost, port 8765
    server = ws_event_loop.run_until_complete(
        websockets.serve(ws_handler, "localhost", 8765)
    )
    print("[WS] WebSocket Server listening on ws://localhost:8765")
    
    # Schedule the autopilot loop in the same event loop
    asyncio.ensure_future(autopilot_loop(), loop=ws_event_loop)
    
    ws_event_loop.run_forever()

# Start WebSocket server in background thread
ws_thread = threading.Thread(target=start_websocket_server, daemon=True)
ws_thread.start()

# --- MCP Tool Registrations ---

@mcp.tool()
def get_game_state() -> str:
    """
    Get the real-time state of the Flappy Bird game.
    Returns bird position, velocity, scores, upcoming pipe gap details, and ground boundaries.
    """
    with state_lock:
        return json.dumps(latest_state, indent=2)

@mcp.tool()
def flap_bird() -> str:
    """
    Trigger the bird to flap (jump) in the running Godot game.
    Useful for playing the game or keeping the bird airborne.
    """
    return send_command_to_godot("flap")

@mcp.tool()
def restart_game() -> str:
    """
    Restarts the game loop when in the GAME_OVER state.
    """
    return send_command_to_godot("restart")

@mcp.tool()
def pause_game() -> str:
    """
    Pause the running Godot game.
    """
    return send_command_to_godot("pause")

@mcp.tool()
def resume_game() -> str:
    """
    Resume the running Godot game if paused.
    """
    return send_command_to_godot("resume")

@mcp.tool()
def set_autopilot(enabled: bool) -> str:
    """
    Enable or disable the built-in autopilot AI that plays the game.
    If enabled, the Python server will automatically guide the bird through the pipe gaps.
    """
    global autopilot_enabled
    autopilot_enabled = enabled
    status = "enabled" if enabled else "disabled"
    return f"Autopilot has been successfully {status}."

if __name__ == "__main__":
    print("[MCP] Starting Python MCP StdIO server...")
    mcp.run()
