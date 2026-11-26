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

Controls: WASD/arrows, Shift sprint, Ctrl hold to crouch, C toggle low cover, Q switch shoulder, E interact, RMB aim, LMB fire while aiming, R reload (or return to the safehouse after mission ends), mouse look, Esc pauses or resumes during exploration and operations.

## Local startup gate

`bash scripts/static-check.sh` runs a narrow syntax sanity check without Godot. The smoke runner invokes it before importing the project. It is not a GDScript parser.

Run `bash scripts/smoke.sh` before playtesting. Set `GODOT_BIN=/path/to/Godot` if the engine is not on PATH. The gate imports the project and runs a short headless startup of the safehouse, briefing, dossier, hotel and archive, failing even on logged script errors with a zero engine exit code. It also runs a campaign/equipment regression scene, with temporary Linux XDG directories so your real campaign is not touched. The test verifies canonical decisions, skill-point limits, persistence, kit isolation, and actual initial agent/combat stats in the hotel and safehouse, plus entering, toggling and leaving physical cover. It does not replace interactive playtesting.

## Local smoke checklist

- Game starts in the walkable safehouse. Approach the operations desk and press E to open the briefing; review objectives, deploy or return to the safehouse without starting the mission; no combat in the safehouse. R after mission completion/failure returns to the safehouse. Verify that campaign state is retained and a new deployment resets mission resources.

- Initial hotel scene loads and renders (confirmed by user screenshot on initial bootstrap).
- Check forward, backward and diagonal movement, sprint and stopping.
- Check turning and limb animation; legs should stop swinging against a wall.
- Q switches camera shoulders; wall collisions and mouse capture/release behave correctly.
- No runtime errors in the debugger.

- Check training target hit feedback and that solid obstacles block shots.
- Guard patrols; suspicion rises with visible player and falls when line of sight breaks. Full detection starts an alert instead of instantly ending the mission. Guard damages the agent at intervals while visible, searches in place after losing sight and eventually resumes patrol. At zero health, the mission fails; R returns to the safehouse. Guard can be defeated using the test combat system.

- Hold Ctrl to crouch: lower collision capsule, camera and movement speed; release to stand when space permits. Crouching reduces guard visual detection, not invisibility. Check crouched aiming and interaction.

- Check ammo consumption on hits and misses, reload from finite reserve, no shots during reload, and no reload after mission end.

- Check health HUD, alert reaction window, no damage behind solid obstacles, search timeout and replay restoring full health.

- Check temporary impact marker, hit-confirmation reticle and red damage flash. These are provisional visual effects and must not intercept input.

- After extraction, choose 1 (share intel with handler) or 2 (retain for leverage). Check distinct trust/leverage outcomes and that the decision is applied once. The first successful debrief records the canonical choice in `user://campaign.cfg` (Godot local app data). Replays never change the first choice or accumulate reputation. Restart Godot to verify persistence. Invalid or unsupported saves are left untouched; failed saves are shown in the debrief.

- The first recorded mission grants one persistent specialization point. At the debrief choose 3 (Resilience: +20 maximum health), 4 (Infiltration: faster crouched movement), or 5 (Mobility: faster sprint). Effects apply on next deployment. The choice is permanent for this prototype save, and replays do not grant additional points. Existing campaign records without a specialization receive the same unspent point. Check save/restart, double selection prevention, and actual effects.

- Briefing allows Standard (24 reserve), Protection (+25 maximum health, 16 reserve), or Supplies (40 reserve). Kits are selected per deployment, never alter the campaign save, and combine with existing specialization. Verify that the safehouse has no kit bonus and that deployment HUD matches the chosen kit.

- Check articulated walk, sprint, crouch and aiming poses on the agent. Guard uses the same visual rig with distinct uniform, patrol animation and alert pose; test its defeat pose. These are procedural placeholders, not skinned character assets.

- Face one of the low brass-topped barriers on the left side of the hotel and press C within reach. Cover constrains movement along the surface, crouches unless aiming, and releases when the barrier ends or C is pressed again. Actual world collision still decides visibility and hit results; no artificial invulnerability. Check both ends and aim/exit transitions.

- Mission debrief and failure show actual elapsed simulation time, health lost, fired shots, target-hit accuracy (including training targets), and guard alert/defeat. The first canonical successful completion saves measured performance with the campaign decision or completion flag. Replays and failures do not overwrite it; older saves may have no report. No performance-based rewards yet.

- Aim transitions blend smoothly with forward-facing arms; mouse sensitivity reduces while RMB is held. Check shoulder switching next to walls, including crouch and aim. Lateral pivot clearance is checked independently of the rear spring arm.

- Unspent specialization points can also be allocated from the next briefing, without replaying a completed mission. Confirming the permanent choice saves it immediately, even if deployment is subsequently cancelled. Failed saves retain the point. Check both briefing and debrief paths.

## Operation catalog

The first operation is now described through a shared catalog. Silent Archive unlocks after the canonical hotel debrief. Select it at the briefing terminal; recover the ledger and return to extraction. Sharing the hotel file opens a closer starting position; retaining it starts at the far entrance. Archive completion persists independently of the first decision and specialization. Both operations remain replayable. The archive environment is procedural and provisional. It has its own patrol route and access/records signage. Isolated regressions instantiate both narrative branches and check spawn, extraction and ledger reachability.

- Original synthesized audio cues accompany fired shots, confirmed hits, reload start, damage, objectives and failure. Cues are built once per field deployment, with bounded players and no external audio assets. Check audible feedback and volume during a real playtest; the safehouse remains silent for now.

- Effects volume can be set from the briefing and saved explicitly (0% mutes new cues). Preferences use `user://settings.cfg`, separate from campaign progress. Failed writes are reported and leave the previous setting active.

- Esc opens a real pause overlay in the safehouse and field missions, suspending physics, guards, combat and mission timers. Resume restores mouse capture. Audio settings are accessible while paused. Terminal debrief/failure states are excluded. Local regressions check pause ownership, resume, terminal exclusion and independent settings persistence.

- A separate FIELD RECORDS terminal in the safehouse opens the agent dossier with canonical mission reports, reputation and specialization. Locked, pending and legacy completions are distinct; no missing metrics are invented. Esc or the return button closes the dossier.

- The dossier contains deterministic handler messages based on the canonical intel decision and actual recorded operation metrics. Missing historical data receives a neutral message. No new reputation changes or invented incidents.

- Short text radio transmissions appear on deployment and objective recovery, reflecting the operation and original hotel decision. Independent archive routes use agent status messages rather than claiming handler support. Messages expire after five simulation seconds, pause with the mission and clear before debrief/failure. No recorded voices or new campaign state.

- The campaign supports a one-time handler agreement after the hotel operation: coordination (+1 trust) or autonomy (-1 trust, +1 leverage). It persists independently of the original route decision, with old saves defaulting to no agreement. Open Secure conversation from FIELD RECORDS to review the offer, explicitly confirm a permanent choice, or return without changing anything. Reopening an agreed conversation is read-only.

- Operational credits derive from the first successful completion of each operation: 100 base, +40 for no full alert, +20 for no damage, +20 for no shots and guard not down. Older completed saves without metrics receive only the base. Replays cannot increase earnings. FIELD RECORDS displays credits. Silent Archive briefing offers a permanent reconnaissance purchase for 60 credits (40 with the coordination agreement, or 50 through Rook with independent leverage). The cheapest eligible supplier is offered automatically; a previous purchase retains its original price and source. The purchased information reflects the actual level layout; ownership and paid cost are persisted atomically. Duplicate purchases are rejected. The original entry route is unchanged.

- Persistent armory inventory supports light armor (80 credits) and utility rig (70 credits). Ownership is unique, purchases debit the same canonical balance as reconnaissance, and incompatible or overspent saves are blocked. The ARMORY terminal is on the left of the safehouse operations desk. Purchases require confirmation and are automatically equipped on field deployments only: armor adds 15 maximum health and utility rig adds 8 reserve rounds, stacking with kits and specialization. The briefing shows owned bonuses. Local smoke includes the armory scene and field stat regressions.

- Rook, an independent supplier, offers a permanent movement kit for 65 credits through the armory. Access requires at least one independent leverage point (retaining the hotel file or choosing autonomy). The kit adds 0.25 to field crouch speed, stacking with specialization. It does not change guard visibility rules. Ownership and expenses use the existing inventory save and balance.

- Rook has independent standing derived from actual purchases from him (+1 each for his movement kit and his reconnaissance). General leverage unlocks access but does not count as reputation. The armory and dossier show the relationship; messages react to recorded dealings. Existing saves derive the same standing without a schema change.

- Rook offers an optional one-time Silent Archive contract via the armory before the first completion. Accept explicitly, then complete the operation without full alert to earn 35 additional credits and one Rook reputation point. The canonical report settles the result; failures before successful extraction can be retried, but replays after completion cannot change it. Legacy completions cannot retroactively accept it. The briefing shows an accepted contract.

- The handler offers an exclusive alternative to Rook before the first Silent Archive completion: no damage for 30 credits and +1 trust. Accepting either contract blocks the other permanently. A successful Rook contract also costs one handler trust point, disclosed at acceptance. Both settle from canonical reports; old saves retain existing acceptance and Rook contracts without recorded penalty terms retain their original no-penalty terms. No retroactive reward. The debrief and dossier show canonical contract settlement; replay debriefs label it archived. Regression covers both successful sponsors, legacy terms and invalid dual acceptance.

## Development policy

Local-first POC. Small PRs and local playtests. No automated CI, deployments, ShadowOps ID or backend until playable POC approval. All geometry and character animation are provisional. Locomotion changes still require runtime validation.
