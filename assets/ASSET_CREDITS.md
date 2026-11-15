# 3D asset credits

## Sound effects

- **Pack:** Sci-Fi Sounds by Kenney
- **Source:** https://kenney.nl/assets/sci-fi-sounds
- **License:** Creative Commons Zero (CC0 1.0)
- **Files:** `audio/sci-fi_sounds/Audio/`
- **User supplied clip:** `audio/sci-fi_sounds/Spaceship start and travelling sound.mp3`, played for the launch and return flight.
- The extracted sound files and license notice are included; the source archive is not committed. The `kenney_*.zip` files that were present in the interrupted download were HTML pages returned by the website, not archives, and were removed.

## Earth and Moon textures

- **Earth:** NASA Blue Marble, “Land Surface, Shallow Water, and Shaded Topography,” 2048 × 1024 map. Source: https://visibleearth.nasa.gov/view.php?id=57752. The project uses a 2K copy from Wikimedia Commons: https://commons.wikimedia.org/wiki/File:Land_shallow_topo_2048.jpg.
- **Moon:** NASA Goddard Space Flight Center Scientific Visualization Studio, CGI Moon Kit (2025 LRO color map, 2048 × 1024). Source: https://svs.gsfc.nasa.gov/4720/. Credit: Ernie Wright (STC) and Noah Petro (NASA/GSFC).
- **Files:** `planets/earth_blue_marble.jpg`, `planets/moon_cgi_kit_color_2k.jpg`.

## Earth arrival cinematic

- **Source video:** User-supplied `earth coming video.mp4`, converted to `earth_coming.ogv` for Godot's built-in video player.
- The MP4 has no audio track; the user-supplied `audio/sci-fi_sounds/Spaceship start and travelling sound.mp3` plays under the arrival video.

## Astronaut

- **Model:** Astronaut by Jungle Jim
- **Source:** https://sketchfab.com/3d-models/astronaut-by-jungle-jim-c775a977606a4e4e990afe783c6bc845
- **License:** Creative Commons Attribution 4.0 (CC BY 4.0)
- **File:** `characters/astronaut_by_jungle_jim.glb`
- The supplied GLB has no skeleton or embedded animation clips. The game applies a small per-vertex leg gait while walking or running and fades it to rest when movement stops.

## Space Shuttle

- **Model:** Space Shuttle by chinmayv2228
- **Source:** https://sketchfab.com/3d-models/space-shuttle-f532bb273d62496cb6b51c76abcd0d6d
- **License:** Creative Commons Attribution 4.0 (CC BY 4.0)
- **File:** `vehicles/space_shuttle.glb`
- The shuttle GLB contains its texture images. Godot imports it as a scene and generates mesh LODs.

## Crew Habitat

- **File:** `crew habitat.glb`, supplied by the user and used for the lunar crew habitat.
- No creator, source URL, or license details were included with the file.

## Alien

- **File:** `aliens/alien_11.obj`, extracted from the user-supplied `18-alien_11.zip`.
- The archive includes only OBJ geometry. It contains no source URL, creator credit, material file, texture, or license notice. The supplied model is not confirmed to be the same asset as the requested Sketchfab reference: https://sketchfab.com/3d-models/another-alien-a58f59bbc77e4e1793d6f28f34473b8c
- The game assigns a PBR material and Godot generates mesh LODs during import.

The two Sketchfab assets above use CC BY 4.0. Retain this attribution file when redistributing those model files.
