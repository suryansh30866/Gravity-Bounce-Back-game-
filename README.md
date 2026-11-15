# Gravity

Gravity is a third-person lunar repair mission made with Godot Engine 4.7. The astronaut must find a damaged return ship, collect its missing parts, repair its cables and systems, and fly the crew back to Earth. The lunar terrain, mission interface, and NPC behaviour are built by the project. The supplied 3D models and shuttle textures are included in `assets/`.

## Requirements

- Godot Engine 4.7 or newer. The game uses GDScript, so the standard Godot build works; .NET is not required.
- Windows, macOS, or Linux with graphics hardware supported by Godot's Forward+ renderer.

## Run the game

1. Clone the repository or download and extract the source archive.
2. In Godot Project Manager, choose **Import** and select this folder's `project.godot` file.
3. Press **F5** to start the expedition menu. To start the mission directly, open `scenes/game.tscn` and press **F6**.

Godot imports the included image, video, and 3D model files on first open. It creates a local `.godot/` cache, which is ignored by Git and does not need to be copied to another computer.

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
- **W / Up, S / Down** — pitch the shuttle during flight
- **A / Left, D / Right** — yaw the shuttle during flight; avoid asteroids

## Mission

1. Follow the blue marker to the damaged return ship.
2. Find and collect eight parts. Your field pack holds eight parts at a time.
3. Use three cable connectors to reconnect power, guidance, and radio.
4. Install the power cell, flight computer, and radio antenna.
5. Repair the engine with a thruster nozzle and coolant pack.
6. Enter the cockpit. Lift off level, build forward thrust, then pitch into the Earth return. Steer around the asteroid field; a collision ends the flight. The Earth arrival video begins at 5 km.

The task list, compass arrow, repair credits, and suit fuel stay on screen. The commander sends a new instruction when each mission step changes. Press **H** for another hint or **C** to review recent messages.

At launch, the shuttle stays horizontal through cabin lock, the five-second countdown, and liftoff. Thrusters raise it through a lunar dust plume before it accelerates forward and makes a gradual gravity turn. During flight, WASD or the arrow keys control pitch and yaw. Asteroids on the return route trigger a mission-ending impact if struck. The surface effect is dust rather than atmospheric smoke, since the Moon has no air.

## Lunar world

Terrain streams in around the astronaut as they travel. Each region is generated from its map coordinates, so revisiting an area gives the same terrain. Near regions use more detail; distant regions use fewer mesh points. Godot culls 3D objects outside the camera view, and the game frees terrain chunks outside the active area.

The generated surface includes impact craters and ejecta rays, dark lunar maria, bright highlands, mountains, rilles, volcanic domes, wrinkle ridges, and a lava-tube skylight. Rock fields, the crew habitat, a relay, and the damaged ship give the surface scale. Eight alien NPCs idle and roam around the playable region; touching one knocks the astronaut backward. The brief knockback cooldown prevents a chain of hits, and movement remains available. The terrain is a stylized game map, not a precise landing-site survey. Moon gravity is set to 1.62 m/s².

Earth is about 7,800 game units from the starting site and has a radius of 130 units, keeping its apparent diameter close to 1.9 degrees from the lunar surface while leaving a wide separation from the Moon. The shuttle transitions to the Earth arrival video once it reaches 5,000 units from Earth, before the 3D vehicle can intersect the globe. The camera far clip and starfield are set for the longer view. The world is scaled for play; the units do not represent the literal Earth–Moon distance.

## Imported models

- The astronaut model is the supplied [Astronaut by Jungle Jim](https://sketchfab.com/3d-models/astronaut-by-jungle-jim-c775a977606a4e4e990afe783c6bc845), licensed CC BY 4.0. The file has no skeleton or embedded animations, so the game animates its legs procedurally during movement and stops the gait while idle.
- The shuttle is the supplied [Space Shuttle by chinmayv2228](https://sketchfab.com/3d-models/space-shuttle-f532bb273d62496cb6b51c76abcd0d6d), licensed CC BY 4.0. Its GLB includes the model textures; Godot generates LODs when it imports the asset.
- The lunar crew habitat uses the user-supplied `assets/crew habitat.glb`, fitted to the site at runtime.
- The alien geometry is from the user-supplied `18-alien_11.zip`. That archive includes an OBJ but no texture, material, source URL, or license notice. The project applies a simple PBR skin material and generates LODs on import. The supplied mesh is not confirmed to be the same model as the linked [Another Alien reference](https://sketchfab.com/3d-models/another-alien-a58f59bbc77e4e1793d6f28f34473b8c).

## Project layout

- `project.godot` — project settings and main scene
- `scenes/` — menu and mission scenes
- `scripts/astronaut.gd` — movement, camera, and controls
- `scripts/alien_npc.gd` — alien roaming, collision areas, and player knockback
- `scripts/lunar_terrain.gd` — procedural terrain, chunk streaming, and surface details
- `scripts/mission_controller.gd` — inventory, repairs, tasks, rewards, hints, and Earth return
- `scripts/home.gd` and `scripts/lunar_backdrop.gd` — expedition menu
- `assets/` — included images, video, astronaut, alien, and shuttle models
- `assets/ASSET_CREDITS.md` — model credits and source notes
- `icon.svg` — project icon

## Visual references

- NASA Goddard Space Flight Center, [Moon 3D Models for Web, AR, and Animation](https://svs.gsfc.nasa.gov/14959/).
- RenderX, [Moon model on Sketchfab](https://sketchfab.com/3d-models/moon-26cc0b7878bb4d919b68e2be399db466). The downloadable mesh is not included in this project.
- Imagine Science, [Space Shuttle Launch realistic animation | 3D Animation | ISS Docking](https://www.youtube.com/watch?v=Y9J4tEqZAjw&t=68s), used as the launch-sequence reference.
