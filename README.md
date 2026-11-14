# Gravity

Gravity is a third-person lunar repair mission made with Godot Engine 4.7. The astronaut must find a damaged return ship, collect its missing parts, repair its cables and systems, and fly the crew back to Earth. Terrain, rocks, the ship, and the mission interface are built by the project. No add-ons or external asset packs are required.

## Requirements

- Godot Engine 4.7 or newer. The game uses GDScript, so the standard Godot build works; .NET is not required.
- Windows, macOS, or Linux with graphics hardware supported by Godot's Forward+ renderer.

## Run the game

1. Clone the repository or download and extract the source archive.
2. In Godot Project Manager, choose **Import** and select this folder's `project.godot` file.
3. Press **F5** to start the expedition menu. To start the mission directly, open `scenes/game.tscn` and press **F6**.

Godot imports the included image and video files on first open. It creates a local `.godot/` cache, which is ignored by Git and does not need to be copied to another computer.

## Controls

- **W A S D** — move
- **Mouse** — look around
- **Space** — jump
- **Shift** — use suit thrust while airborne
- **E** — pick up a part or use a repair station
- **I** — open or close the inventory
- **H** — ask Mission Control for a hint
- **C** — open or close the command log
- **Tab** — release or capture the mouse
- **Esc** — close a panel or return to the menu
- **R** — play again after landing on Earth

## Mission

1. Follow the blue marker to the damaged return ship.
2. Find and collect eight parts. Your field pack holds eight parts at a time.
3. Use three cable connectors to reconnect power, guidance, and radio.
4. Install the power cell, flight computer, and radio antenna.
5. Repair the engine with a thruster nozzle and coolant pack.
6. Enter the cockpit. Mission Control guides the launch and Earth return.

The task list, compass arrow, repair credits, and suit fuel stay on screen. The commander sends a new instruction when each mission step changes. Press **H** for another hint or **C** to review recent messages.

## Lunar world

Terrain streams in around the astronaut as they travel. Each region is generated from its map coordinates, so revisiting an area gives the same terrain. Near regions use more detail; distant regions use fewer mesh points. Godot culls 3D objects outside the camera view, and the game frees terrain chunks outside the active area.

The generated surface includes impact craters and ejecta rays, dark lunar maria, bright highlands, mountains, rilles, volcanic domes, wrinkle ridges, and a lava-tube skylight. Rock fields, the crew habitat, a relay, and the damaged ship give the surface scale. The terrain is a stylized game map, not a precise landing-site survey. Moon gravity is set to 1.62 m/s².

## Project layout

- `project.godot` — project settings and main scene
- `scenes/` — menu and mission scenes
- `scripts/astronaut.gd` — movement, camera, and controls
- `scripts/lunar_terrain.gd` — procedural terrain, chunk streaming, and surface details
- `scripts/mission_controller.gd` — inventory, repairs, tasks, rewards, hints, and Earth return
- `scripts/home.gd` and `scripts/lunar_backdrop.gd` — expedition menu
- `assets/` — included image and video files
- `icon.svg` — project icon

## Visual references

- NASA Goddard Space Flight Center, [Moon 3D Models for Web, AR, and Animation](https://svs.gsfc.nasa.gov/14959/).
- RenderX, [Moon model on Sketchfab](https://sketchfab.com/3d-models/moon-26cc0b7878bb4d919b68e2be399db466). The downloadable mesh is not included in this project.
