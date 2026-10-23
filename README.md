# Contra Re (Godot 4 - Android & PC)

An eight-stage 2D action game inspired by **Contra**, built in **GDScript** for standard **Godot 4.7**, with Android and PC support.

---

## 🎮 Gameplay Features

- **Iconic Commando Physics & Controls**:
  - Full **8-directional aiming**: shoot straight, straight up, diagonally up/down, and straight down while in mid-air.
  - **Prone / Crouch**: Lie flat on the ground to dodge enemy rifle bullets while returning fire along the deck.
  - **Somersault Jump**: Authentic curled spinning commando jump flip with drop-through platform mechanics (`Down + Jump`).
  - **Invulnerability & Respawn**: Parachuting commando respawn drop with flashing invulnerability state.
- **Weapon Arsenal**:
  - **Rifle (Standard)**: Fast single bullet.
  - **Spread Gun (S)**: 5-way fan spread of high-impact plasma pellets.
  - **Machine Gun (M)**: Automatic high-cadence rapid bullet stream.
  - **Laser Gun (L)**: High-energy piercing laser beam.
  - **Flying Power-up Blimps**: Floating capsules hovering in sinusoidal wave patterns that pop to drop weapon badges.
- **Enemy Vanguard**:
  - **Red Infantrymen**: Running soldiers charging and jumping gaps while taking potshots.
  - **Pillbox Turrets**: Rotating bunkers tracking player position and firing bursts of bullets.
  - **Platform Snipers**: Camouflaged marksmen aiming long rifles from elevated vantage points.
- **Stage 1 Wall Defense Boss**:
  - Massive armored entrance fortress with twin heavy cannons, top hatch defense, and glowing alien core sensor with chained explosion sequences upon defeat.
- **Title Screen & Tactical Level Selection**:
  - **Retro Arcade Title Screen**: Metallic red & gold **CONTRA RE** logo, glowing falcon insignia, animated starfield, and retro synth music cues.
  - **Interactive Start Menu**: `START MISSION`, `SELECT LEVEL`, `HOW TO PLAY` (briefing dialog), and `SOUND TOGGLE`.
  - **Mission Level Select**: Tactical theater deployment cards for **Stage 1 (Jungle Perimeter)**, **Stage 2 (Waterfall Fortress)**, and **Stage 3 (Alien Hive Core)** with mission objectives and custom backdrop themes.

---

## 🕹️ Controls

### Android Touchscreen
- **Left Side Virtual D-Pad**: Move Left / Right, Aim Up / Down, and 8-way diagonal combinations.
- **(A) Blue Button**: Jump (Press Down on D-Pad + Jump to drop down through bridges).
- **(B) Red Button**: Shoot (Hold for continuous Machine Gun fire).
- **Top Right Buttons**: Quick Restart & `[MENU]` Button (return to Level Select / Title Screen).
- **Menus & Level Select**: Directly tap cards or menu options to deploy.

### PC / Keyboard Controls
| Action | Key |
| :--- | :--- |
| **Move / Aim** | `W, A, S, D` or `Arrow Keys` |
| **Jump / Confirm** | `Space` or `K` / `Enter` |
| **Shoot** | `J` or `X` |
| **Drop Through Platform** | `S + Space` / `Down + Jump` |
| **Prone (Crouch)** | Hold `S` / `Down` |
| **Restart Current Stage** | `R` |
| **Return to Menu / Title** | `M` or `Esc` |

---

## 📱 Android APK Installation

The pre-built signed APK is located in:
```
builds/ContraRe.apk
```

To install on a connected Android phone or emulator via ADB:
```powershell
adb install -r builds/ContraRe.apk
```
Or transfer `ContraRe.apk` to your Android device and tap to install (enable "Install unknown apps" if prompted).

---

## 💻 Running on PC

You can run the game directly on Windows:
```powershell
.\builds\ContraRe.exe
```

Or open the project in standard Godot 4.7 (the game does not require .NET):
```powershell
godot --path .
```

## Campaign progression

| Stage | Route progression |
| --- | --- |
| 1 — Jungle | Beach training, outpost flank, canopy ledges, mech, two river routes, fortress assault |
| 2 — Waterfall | Foothill ascent, basin descent, supply shelves, mech, three-spire climb |
| 3 — Hive | Low combat chambers, elevated rib routes, unstable tissue, mech, organ shelves |
| 4 — Tundra | Broad slippery fields, steel braking decks, icicle shelves, mech, glacier assault |
| 5 — Refinery | Production decks, vent trenches, conveyor supply routes, mech, furnace gantries |
| 6 — Dynamo | Safe observation decks, surge platforms, upper circuits, mech, charged towers |
| 7 — Hangar | Cargo bays, fixed gantries or optional lifts, tripwire ambushes, mech, launch deck |
| 8 — Sanctum | Neural gate, sentry flanks, unstable synapses, mech, layered final defenses |

All default maps avoid rope bridge platforms. Each stage includes a quiet rearm stretch after its mini-boss.

Campaign revision 2 takes precedence over older editor overrides during normal play.
Older custom stage files are preserved and still load in Contra Maker. Saving one again,
or explicitly loading a saved slot, makes that custom map the active override again.
Lift tags, lift amplitudes, and falling-platform delays survive editor saves.

Run the static layout check with `python tests/check_campaign_routes.py`. It checks
forward jumps using player movement constants, fixed routes through every ground section,
weapon-support access, bridge exclusion, and boss floor continuity. Optional moving and
falling routes use their initial platform positions; hazard timing and combat need playtesting
in standard Godot.
