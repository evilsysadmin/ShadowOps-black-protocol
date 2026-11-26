# ShadowOps: Black Protocol

An independent third-person espionage action RPG in the ShadowOps universe. Original characters, missions and assets. One agent, competing factions, infiltration, real-time action and lasting consequences.

## Local development (Linux)

Godot 4 only. Use a native package if available or download the Linux executable from https://godotengine.org/download/linux/ and put it on PATH. No npm, backend or export templates needed.

From the repository root:

```sh
godot --path .
# Editor (F5 to play):
godot -e --path .
```

Controls: WASD/arrows, Shift sprint, Q switch shoulder, mouse look, Esc releases the pointer, left click recaptures it.

## Local smoke checklist

- Initial hotel scene loads and renders (confirmed by user screenshot on initial bootstrap).
- Check forward, backward and diagonal movement, sprint and stopping.
- Check turning and limb animation; legs should stop swinging against a wall.
- Q switches camera shoulders; wall collisions and mouse capture/release behave correctly.
- No runtime errors in the debugger.

## Development policy

Local-first POC. Small PRs and local playtests. No automated CI, deployments, ShadowOps ID or backend until playable POC approval. All geometry and character animation are provisional. Locomotion changes still require runtime validation.
