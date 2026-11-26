# ShadowOps: Black Protocol

An independent third-person espionage action RPG in the ShadowOps universe. Original characters, missions and assets. One agent, competing factions, infiltration, real-time action and lasting consequences.

First milestone: a playable Godot 4 Compatibility prototype, with movement, shoulder camera, a small fictional hotel, interaction and extraction. No production deployment yet.

## Local development (Linux)

Godot 4 only; no npm, backend or export templates required for local play. Install Godot from your distribution or Flathub:

```sh
flatpak install flathub org.godotengine.Godot
flatpak run org.godotengine.Godot --path "$PWD"
```

Run from the repository root. With a native Godot 4 executable, use `godot --path .` (or `godot4 --path .`, depending on packaging). Open the editor using `-e --path .`; F5 runs the project.

Controls: WASD/arrows, mouse look, Esc releases the pointer, left click recaptures it.

### Local smoke checklist

- Project opens without parser errors and loads the hotel scene.
- Agent moves, camera follows and mouse capture can be released/reacquired.
- Walls and furniture block movement; camera does not pass through solid geometry.
- No runtime errors in the debugger.

### Development policy

Local-first POC. Iterate on small PRs and validate playable changes locally. No automated CI, production deployments, ShadowOps ID or backend until the playable POC is approved. Assets and geometry are placeholders. No runtime validation has yet been recorded.
