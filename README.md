# Gather Now - Multiplayer Social Game

A 2D top-down multiplayer social game similar to Gather.town, built with Godot 4.5.

## Quick Start

### Running the Game

1. Open the project in Godot 4.5+
2. Press F5 or click "Run Project"
3. The game will start at the login screen

### Hosting a Server

1. Enter your username and click "Join"
2. Select your character and click "Enter World"
3. Click "Host Game" on the multiplayer menu
4. The server will start on port 7777 by default
5. Share your IP address with other players

### Joining a Server

1. Enter your username and click "Join"  
2. Select your character and click "Enter World"
3. Enter the host's IP address (default: 127.0.0.1 for local testing)
4. Enter the port (default: 7777)
5. Click "Join Game"

### Local Testing (2 Players)

1. Run two instances of the game (you can export and run, or use Godot's "Run Multiple Instances" feature)
2. Instance 1: Host a game
3. Instance 2: Join 127.0.0.1:7777

## Controls

| Key | Action |
|-----|--------|
| W / Up Arrow | Move Up |
| S / Down Arrow | Move Down |
| A / Left Arrow | Move Left |
| D / Right Arrow | Move Right |
| M | Toggle Microphone |

## Project Structure

```
gather-now/
├── assets/sprites/          # Character sprites, tiles, icons
├── networking/
│   ├── NetworkManager.gd    # Multiplayer connection & sync
│   └── VoiceManager.gd      # Proximity voice chat system
├── scenes/
│   ├── Main.tscn            # Entry point, screen manager
│   ├── Player.tscn          # Networked player character
│   └── Office.tscn          # Game map with areas
├── scripts/
│   ├── Player.gd            # Movement & collision
│   ├── PlayerManager.gd     # Spawn/despawn players
│   └── AreaDetector.gd      # Named area detection
├── ui/
│   ├── LoginScreen.tscn     # Username input
│   ├── CharacterSelect.tscn # Character picker
│   ├── HostJoinMenu.tscn    # Multiplayer menu
│   └── GameHUD.tscn         # In-game overlay
└── project.godot            # Project configuration
```

## Voice Chat Implementation

The voice chat system is located in `networking/VoiceManager.gd`.

### How Proximity Detection Works

1. Every physics frame, distance is calculated between the local player and all other players
2. **Near range (< 100px)**: Full volume voice
3. **Far range (> 200px)**: No voice, player exits chat
4. **In between**: Linear volume fade

### Current Implementation

- ✅ Full proximity detection logic with signals
- ✅ Mic toggle (M key) with UI indicators
- ✅ Speaking state detection (stub)
- ✅ Nearby players list in HUD
- ⬜ Actual audio capture/streaming (stubbed)

### Extending with Real Voice

To add actual voice chat, you have two options:

#### Option A: Godot's Built-in Audio (Local only)

```gdscript
# In VoiceManager._setup_audio_capture():
# 1. Create an "Mic" audio bus with AudioEffectCapture
# 2. Use AudioStreamMicrophone for input
# 3. Send captured audio frames via custom RPC or UDP
```

#### Option B: WebRTC (Recommended for production)

```gdscript
# Use Godot's WebRTC implementation:
# 1. Create WebRTCPeerConnection per nearby player
# 2. Add audio track from local microphone
# 3. Handle ICE candidates exchange via your RPC system
# 4. Attach received audio to AudioStreamPlayer2D
```

### Key Extension Points in VoiceManager.gd

- `_start_audio_capture()` - Start microphone recording
- `_stop_audio_capture()` - Stop microphone recording  
- `_get_mic_input_level()` - Get current volume for speaking detection
- `_create_audio_player_for_peer()` - Setup audio playback for remote player
- `_update_audio_player_volume()` - Adjust volume based on distance

## Networking Architecture

Uses Godot's High-Level Multiplayer API with **ENet** (reliable UDP).

### Server/Client Model

- One player hosts (server authority)
- All position updates sync via MultiplayerSynchronizer
- Player data (username, character) synced via RPC on join
- Username uniqueness validated server-side

### Synced Data

- Player spawn/despawn events
- Player position (interpolated)
- Player username and character selection
- Mic toggle state (for indicators)

## Known Limitations

- Voice chat is stubbed (proximity logic works, actual audio not implemented)
- No persistent login (username is session-only)
- Single map (Office) - easy to add more by creating new scenes
- No chat system (voice-only)

## License

MIT
