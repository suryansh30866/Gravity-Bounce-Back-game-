# Gravity

Gravity is a third-person lunar surface expedition built with Godot Engine 4.7. The terrain, astronaut, landmarks, and UI are generated from GDScript, so no external asset pack or add-on is needed.

## Requirements

- Godot Engine 4.7 or newer. The project uses GDScript and works with the standard Godot editor/runtime; .NET is not required.
- A desktop operating system supported by Godot (Windows, macOS, or Linux) and graphics hardware that supports the Forward+ renderer.

## Run from a fresh checkout

1. Clone this repository or download and extract its source archive.
2. In Godot Project Manager, choose **Import**, select this folder's `project.godot`, and import the project.
3. Open `scenes/home.tscn` and press **F6** to run the menu, or open `scenes/game.tscn` and press **F6** to start directly in the mission. Press **F5** to run the configured main scene (the expedition menu).

Godot imports the included image/video assets on first open and creates a local `.godot/` cache. That cache is ignored by Git and does not need to be copied between computers.

## Controls

- **W A S D** — move
- **Mouse** — orbit the follow camera
- **Space** — low-gravity jump
- **Shift** — suit thrust while airborne
- **E** — restore the lander, then transmit from the ridge relay
- **Esc** — return to the expedition menu
- **R** — replay after completing the mission

Follow the objective marker from the habitat to the lander, restore its power console, reach the relay, and return to the habitat. Horizontal movement and suit thrust are tuned for the Moon's 1.62 m/s² surface gravity.

## Project layout

- `project.godot` — Godot project settings and main scene
- `scenes/` — expedition menu and playable mission scene
- `scripts/` — menu, astronaut controller, terrain generation, and mission logic
- `assets/` — source visuals included with the project
- `icon.svg` — project icon

## Surface features

The playable 252 m square is generated with a collision mesh and includes impact craters and ejecta streaks, a dark mare plain, brighter highland relief, a distant mountain chain, a sinuous rille, volcanic domes, a wrinkle ridge, and a collapsed lava-tube skylight. Procedural rock fields, dust shading, Earthrise, the habitat, lander, and relay provide scale and mission landmarks.

The terrain is a stylized game representation, rather than a geographically precise landing site. The menu and HUD call out Mare Tranquillitatis and lunar feature types.

## Visual references

- NASA Goddard Space Flight Center, [Moon 3D Models for Web, AR, and Animation](https://svs.gsfc.nasa.gov/14959/). Its LRO-derived model notes the contrast between smooth, dark mare plains and rugged, brighter highlands.
- RenderX, [Moon model on Sketchfab](https://sketchfab.com/3d-models/moon-26cc0b7878bb4d919b68e2be399db466), used as a visual reference. That downloadable mesh is not included in this project.

- **W A S D** — move
- **Mouse** — orbit the follow camera
- **Space** — low-gravity jump
- **Shift** — suit thrust while airborne
- **E** — restore the lander, then transmit from the ridge relay
- **Esc** — return to the expedition menu
- **R** — replay after completing the mission

Follow the objective marker from the habitat to the lander, restore its power console, reach the relay, and return to the habitat. Horizontal movement and suit thrust are tuned for the Moon's 1.62 m/s² surface gravity.

## Surface features

The playable 252 m square is generated with a collision mesh and includes impact craters and ejecta streaks, a dark mare plain, brighter highland relief, a distant mountain chain, a sinuous rille, volcanic domes, a wrinkle ridge, and a collapsed lava-tube skylight. Procedural rock fields, dust shading, Earthrise, the habitat, lander, and relay provide scale and mission landmarks.

The terrain is a stylized game representation, rather than a geographically precise landing site. The menu and HUD call out Mare Tranquillitatis and lunar feature types.

## Visual references

- NASA Goddard Space Flight Center, [Moon 3D Models for Web, AR, and Animation](https://svs.gsfc.nasa.gov/14959/). Its LRO-derived model notes the contrast between smooth, dark mare plains and rugged, brighter highlands.
- RenderX, [Moon model on Sketchfab](https://sketchfab.com/3d-models/moon-26cc0b7878bb4d919b68e2be399db466), used as a visual reference. That downloadable mesh is not included in this project.
