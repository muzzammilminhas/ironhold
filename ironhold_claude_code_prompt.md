# Ironhold — Build Instructions

You are an autonomous coding agent building **Ironhold** (working title — rename freely if a better one occurs to you), a complete, shippable 3D arena survivor game in **Godot 4**, targeting Android and Web (HTML5) exports from a single codebase. You are starting from a completely empty project folder. Work through this document end to end without stopping for confirmation except where explicitly noted below.

<critical_requirements>
These apply across every phase and override any instinct to cut scope. Re-read this block before starting each new phase.

1. **No placeholders.** No placeholder art, placeholder text, "TODO" stubs, grey boxes, or "coming soon" screens anywhere in the shipped build. Every phase should leave a genuinely playable, finished-feeling slice. The end state is a finished, polished product — not a prototype or tech demo.
2. **60fps, non-negotiable.** The game must hold 60fps on both the Android build and the web export, at the enemy counts and effect density this document defines. This is a hard constraint, checked at the end of every phase from Phase 4 onward, not a pass you do once at the end.
3. **Real algorithms, not approximations that only look right.** Enemy pathfinding must use Godot's `NavigationAgent3D` against a baked navmesh — never a straight-line "move toward player" vector. This is the technical centerpiece of the project.
4. **Full autonomy.** Design ambiguities (exact damage numbers, spawn-rate curve, obstacle density, exact upgrade values) are never a reason to stop — make a reasonable choice, note it in a code comment, and keep moving. Only stop for the two genuine hard blockers named explicitly in this document (missing asset packs, missing GitHub auth).
5. **Real deliverables at the end, not just source code**: a pushed GitHub repo with real commit history, a final signed installable Android APK, and a `linkedin-post/` folder with real screenshots and a caption. These are defined in detail in Phase 8.
</critical_requirements>

## What you're building

A third-person 3D fantasy arena survivor game, in the "Vampire Survivors" loop but rendered in real 3D: the player is a knight who survives escalating waves of enemies for 5-10 minutes per run, gaining XP and choosing upgrades along the way, inside a procedurally arranged arena. Enemies pathfind around obstacles to chase the player and flock together naturally instead of clumping or clipping through geometry.

## Asset pipeline — supplied by your human collaborator, not sourced by you

Character models and animations come from Quaternius (quaternius.com), CC0 licensed:
- Player: the "RPG Character Pack" (a warrior/knight-style character, ~14 animations including Idle, Death, Attack, Run, Roll, Walk).
- Enemies: "LowPoly Animated Monsters" (skeleton and other monsters, with walk/attack/other animations).

Your human collaborator is responsible for downloading these and placing the `.glb` files into `res://assets/characters/player/` and `res://assets/characters/enemies/<type>/`. **If these files are not present when you reach the point of needing them, stop and ask for them rather than substituting placeholder geometry or attempting to source assets yourself.** If a pack's animation track names don't match what your code expects, fix it via Godot's import remap rather than hardcoding around missing animations.

## Tech stack

- Godot 4.x, GDScript
- `NavigationRegion3D` + `NavigationAgent3D` for enemy pathfinding, baked at runtime after arena generation
- glTF import for all character assets (Godot's native importer, no plugin needed)
- Git for version control from the first commit
- No backend, no networking, no login — fully offline single-player

## Version control and GitHub

Run `git init` in the project root as your first action, before any other work. Commit at the end of every phase with a message describing what was completed, so the history reads as real incremental progress, not one giant final commit.

To get the repo onto GitHub: check whether `gh` (GitHub CLI) is already authenticated on this machine. If it is, run `gh repo create ironhold --public --source=. --push` once your first commit exists, then push after every subsequent phase. **If `gh` is not authenticated, this is a genuine hard blocker** — stop and ask your human collaborator to either run `gh auth login` once, or create an empty repo on github.com and give you the remote URL to add with `git remote add origin <url>`. You cannot create a GitHub account or authenticate on your own, so don't attempt to work around this.

## Performance target — 60fps

Profile with Godot's built-in monitor/profiler at the end of every phase that adds visual or AI load (Phase 4 onward). If frame time creeps up, fix it immediately rather than deferring: object-pool enemies instead of instantiating/freeing them each spawn, cap particle and effect counts, simplify materials, throttle nav-agent recalculation frequency. Do not move to the next phase carrying a known performance regression.

## Project structure

```
res://
  assets/characters/player/
  assets/characters/enemies/skeleton/
  assets/arena/            # modular floor/obstacle pieces (simple primitives/CSG to start)
  scenes/
    Player.tscn
    Enemy.tscn
    Arena.tscn
    UpgradeUI.tscn
    Main.tscn
  scripts/
    player_controller.gd
    enemy_ai.gd
    arena_generator.gd
    wave_spawner.gd
    upgrade_system.gd
    game_state.gd
```

## Core systems

**Player controller** (`player_controller.gd`) — Third-person camera, slightly elevated, follows behind the player. Movement via `CharacterBody3D`. Attack on input, auto-targeting the nearest enemy in range, playing the attack animation and dealing damage. Dodge/roll on a short cooldown. Health, XP, and level tracked here or in a shared `game_state.gd` autoload.

**Enemy AI** (`enemy_ai.gd`) — Each enemy is a `CharacterBody3D` with a `NavigationAgent3D`. On spawn, set the nav target to the player and move along `nav_agent.get_next_path_position()` every frame. Add a small separation force, steering away from nearby enemies, weighted lightly relative to the nav-follow force, so groups flock naturally instead of overlapping. Drive walk/attack/death animations off state.

**Arena generation** (`arena_generator.gd`) — At the start of each run, procedurally place obstacle pieces (pillars, rubble, low walls — simple primitive meshes or CSG shapes are fine) within the arena bounds, using a placement algorithm that avoids overlap and keeps the center reasonably open. Bake the `NavigationRegion3D` after placement. Log the seed used so a run can be reproduced for debugging.

**Wave spawner** (`wave_spawner.gd`) — Timer-driven waves, spawning enemies at arena-edge points at an escalating rate as run time increases. Cap live enemy count (start around 15-20 concurrent, raise only after profiling confirms headroom).

**Upgrade system** (`upgrade_system.gd`) — On level-up, pause and present 3 random upgrade choices (e.g. +damage, +move speed, +attack range, +max health, new attack). Apply the chosen change and resume.

**Game state** (`game_state.gd`, autoload) — Tracks run timer, score, player stats, current wave. On death, show survival time and enemies defeated, offer restart.

## Controls

- Mobile: on-screen virtual joystick (left) for movement, single attack button (right), dodge as a swipe or second button.
- Web: WASD for movement, mouse click or spacebar to attack, shift to dodge.
- Both should share the same Input Map action names so `player_controller.gd` doesn't need platform-specific branches beyond which on-screen UI is visible.

## Build order

Confirm each phase runs correctly on both an Android build and a web export before moving to the next. Commit to git at the end of each one.

**Phase 1 — Scaffold and static scene.** Project setup, folder structure, import the player model, static arena with a few hardcoded obstacles, third-person camera. Confirm the character renders and idles correctly on both export targets.

**Phase 2 — Player movement and combat.** Movement, attack input, dodge, animations wired to state. A single training-dummy target to confirm damage and attack timing feel right.

**Phase 3 — Procedural arena and navmesh.** Implement `arena_generator.gd`, bake `NavigationRegion3D` at runtime, confirm a fresh layout each run.

**Phase 4 — Enemy AI.** Import the skeleton model, implement pathfinding and flocking in `enemy_ai.gd`, spawn a handful manually to confirm they path around obstacles instead of through them. First profiling checkpoint.

**Phase 5 — Wave spawner and XP/upgrades.** Escalating waves, XP on kill, level-up upgrade choice UI.

**Phase 6 — Game state and UI polish.** Health/XP/timer HUD, death screen with stats, restart flow.

**Phase 7 — Mobile controls, responsive UI, and export pass.** On-screen joystick/buttons for mobile, confirm keyboard/mouse still works for web, hit the 60fps target on both exports before continuing.

**Phase 8 — Release packaging (final deliverables).**
- Build the final signed, release-mode Android APK (not a debug build), placed clearly in the repo (e.g. `builds/ironhold.apk`). If a phone is connected via USB with debugging enabled, install it directly with `adb install`; otherwise your human collaborator will transfer the file and install it manually — either way, the APK itself must be finished and installable, never a debug or placeholder build.
- Push the final repo state to GitHub.
- Create a `linkedin-post/` folder in the repo root containing 4-6 real gameplay screenshots (combat, the level-up choice screen, the death/stats screen, and an arena overview are good picks) and a `caption.txt` with a short, genuine caption describing the project — mention Godot, 3D, procedural arena generation, and the real pathfinding/flocking AI specifically, since those are the actual technical differentiators.

**Phase 9 — stretch, only once every phase above is solid and shipped.** A second enemy type from the monster pack, ranged attacks, a boss wave at the end of a run.

<final_check>
Before considering the project done, verify against <critical_requirements> one more time: no placeholders anywhere, 60fps confirmed on both exports, GitHub repo pushed with real history, a final signed APK present and installable, and the `linkedin-post/` folder populated with real screenshots and a caption.
</final_check>
