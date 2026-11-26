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

Controls: WASD/arrows, Shift sprint, Ctrl hold to crouch, Q switch shoulder, E interact, RMB aim, LMB fire while aiming, R reload (or replay after mission ends), mouse look, Esc releases the pointer, left click recaptures it.

## Local startup gate

Run `bash scripts/smoke.sh` before playtesting. Set `GODOT_BIN=/path/to/Godot` if the engine is not on PATH. The gate imports the project and runs a short headless startup, failing even on logged script errors with a zero engine exit code. It does not validate gameplay.

## Local smoke checklist

- Initial hotel scene loads and renders (confirmed by user screenshot on initial bootstrap).
- Check forward, backward and diagonal movement, sprint and stopping.
- Check turning and limb animation; legs should stop swinging against a wall.
- Q switches camera shoulders; wall collisions and mouse capture/release behave correctly.
- No runtime errors in the debugger.

- Check training target hit feedback and that solid obstacles block shots.
- Guard patrols; suspicion rises with visible player and falls when line of sight breaks. Full detection starts an alert instead of instantly ending the mission. Guard damages the agent at intervals while visible, searches in place after losing sight and eventually resumes patrol. At zero health, the mission fails; R retries. Guard can be defeated using the test combat system.

- Hold Ctrl to crouch: lower collision capsule, camera and movement speed; release to stand when space permits. Crouching reduces guard visual detection, not invisibility. Check crouched aiming and interaction.

- Check ammo consumption on hits and misses, reload from finite reserve, no shots during reload, and no reload after mission end.

- Check health HUD, alert reaction window, no damage behind solid obstacles, search timeout and replay restoring full health.

- Check temporary impact marker, hit-confirmation reticle and red damage flash. These are provisional visual effects and must not intercept input.

- After extraction, choose 1 (share intel with handler) or 2 (retain for leverage). Check distinct trust/leverage outcomes and that the decision is applied once. The first successful debrief records the canonical choice in `user://campaign.cfg` (Godot local app data). Replays never change the first choice or accumulate reputation. Restart Godot to verify persistence. Invalid or unsupported saves are left untouched; failed saves are shown in the debrief.

- The first recorded mission grants one persistent specialization point. At the debrief choose 3 (Resilience: +20 maximum health), 4 (Infiltration: faster crouched movement), or 5 (Mobility: faster sprint). Effects apply on next deployment. The choice is permanent for this prototype save, and replays do not grant additional points. Existing campaign records without a specialization receive the same unspent point. Check save/restart, double selection prevention, and actual effects.

## Development policy

Local-first POC. Small PRs and local playtests. No automated CI, deployments, ShadowOps ID or backend until playable POC approval. All geometry and character animation are provisional. Locomotion changes still require runtime validation.
