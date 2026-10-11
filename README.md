# Contra Re (Godot 4 - Android & PC)

An authentic retro arcade clone of **Contra** (Stage 1 Jungle & Wall Defense Core), built in **Godot 4.7** with native Android export and PC support.

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
- **Visuals & Audio**:
  - **Multi-Touch Android Controls**: Responsive on-screen virtual 8-way D-Pad, Jump (A), and Shoot (B) buttons.
  - **Procedural 8-bit Sound Synthesizer**: Zero external audio dependencies—all sound effects (gunshots, spread bursts, explosions, laser sweeps, jumps, powerups, boss siren) are mathematically synthesized at runtime into WAV streams.
  - **CRT Scanline Arcade Post-Processing**: Toggleable shader simulating retro CRT monitor scanlines, curvature, and chromatic aberration.

---

## 🕹️ Controls

### Android Touchscreen
- **Left Side Virtual D-Pad**: Move Left / Right, Aim Up / Down, and 8-way diagonal combinations.
- **(A) Blue Button**: Jump (Press Down on D-Pad + Jump to drop down through bridges).
- **(B) Red Button**: Shoot (Hold for continuous Machine Gun fire).
- **Top Right Buttons**: Toggle CRT shader & Quick restart.

### PC / Keyboard Controls
| Action | Key |
| :--- | :--- |
| **Move / Aim** | `W, A, S, D` or `Arrow Keys` |
| **Jump** | `Space` or `K` |
| **Shoot** | `J` or `X` |
| **Drop Through Platform** | `S + Space` / `Down + Jump` |
| **Prone (Crouch)** | Hold `S` / `Down` |
| **Toggle CRT Shader** | `C` |
| **Restart Game** | `R` |
| **Quit Game** | `Esc` |

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

Or open the project in Godot 4.7:
```powershell
& "D:\GitHub\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe" --path .
```
