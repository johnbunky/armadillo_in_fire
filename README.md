# Armadillo in Fire 🦔🔥
A survival game built with [LÖVE](https://love2d.org/) (Lua). Guide your armadillo through spreading fires — push the stone into flames before they overwhelm you.

---

## Project Structure

```
project/
  main.lua          ← game entry point, C config table, adapt() AI
  conf.lua          ← LÖVE window/system settings
  assets/
    armadillo.png   ← menu background image
    sounds/         ← generated .wav files (see below)
  src/
    audio.lua       ← sound system (generated sounds, web-safe)
    ball.lua        ← armadillo + stone drawing, physics state
    fire.lua        ← particle fire system
    menu.lua        ← all menu states, platform-aware
    physics.lua     ← collision, boundary, push logic
    screen.lua      ← resolution scaling, coordinate conversion
    stain.lua       ← burn mark dissolve effect
    ui.lua          ← health bar, screen-edge damage flash
  soundgen/
    main.lua        ← one-shot sound generator (see below)
  output_folder/    ← love.js web build output
    index.html      ← patched manually (keep this file safe!)
    game.data       ← packed game (regenerated each build)
    ...
```

---

## Running the Game

```bash
# Desktop
love .

# Fullscreen toggle in-game
F11
```

---

## Generating Sound Files

LÖVE can generate sounds programmatically, but love.js (web) crashes on `love.sound.newSoundData`. The solution is to bake the sounds to `.wav` files once on desktop, then commit them.

**You only need to do this once**, or if you change `soundgen/main.lua`.

### Steps

1. Make sure `soundgen/main.lua` exists in the project
2. Run the generator:
```bash
love soundgen
```
3. LÖVE prints the save directory on screen, e.g.:
```
C:\Users\yourname\AppData\Roaming\LOVE\lovegame\assets\sounds\
```
4. Copy the generated files into your project:
```bash
# Windows
copy "C:\Users\yourname\AppData\Roaming\LOVE\lovegame\assets\sounds\*" assets\sounds\

# Mac/Linux
cp ~/.local/share/love/lovegame/assets/sounds/* assets/sounds/
```
5. Verify 6 files exist:
```
assets/sounds/bounce.wav
assets/sounds/push.wav
assets/sounds/pickup.wav
assets/sounds/fire_crackle.wav
assets/sounds/fire_extinguish.wav
assets/sounds/fire_damage.wav
```
6. Commit `assets/sounds/` to the repo — never needs regenerating unless you change the sound design.

---

## Web Build (love.js)

### Prerequisites

```bash
npm install -g love.js
```

### Build and test locally

```bash
# 1. Pack the game into a .love file (must be zip format, not 7z)
Remove-Item mygame.love
7z a -tzip mygame.love main.lua conf.lua src assets

# 2. Build web output
node "C:\Users\yourname\AppData\Roaming\npm\node_modules\love.js\index.js" mygame.love output_folder -t "YourGameTitle"

# 3. IMPORTANT: restore patched index.html (the build overwrites it)
copy index_patched.html output_folder\index.html

# 4. Serve locally
cd output_folder
python3 server.py
# open http://localhost:3000
```

### index.html patch (important)

After every love.js rebuild, the generated `index.html` must be replaced with the patched version. The patch removes:
- The `<h1>` title bar (takes vertical space, clips canvas bottom)
- The `<footer>` bar (blocks clicks on lower canvas area)

**Keep `index_patched.html` in the project root** and always copy it after rebuilding.

### Upload to itch.io

```bash
# Zip the output_folder contents (not the folder itself)
cd output_folder
7z a -tzip ../web_build.zip *
```

On itch.io:
- Edit game → Uploads → upload `web_build.zip`
- Kind: **HTML**
- Check: **"This file will be played in the browser"**

---

## Android Build

### Prerequisites

- [love-android SDK](https://github.com/love2d/love-android)
- Android Studio (or `apktool` for command-line only)
- Java JDK

### Steps (Android Studio path)

1. Clone love-android: `git clone https://github.com/love2d/love-android`
2. Copy your `.love` file into `love-android/app/src/main/assets/game.love`
3. Edit `love-android/app/src/main/AndroidManifest.xml`:
   - Set `android:screenOrientation="portrait"` (or `"landscape"`)
   - Set `android:label="Your Game Title"`
4. Open in Android Studio → Build → Generate Signed APK
5. Sign with your keystore (create one if first time: `keytool -genkey -v -keystore my.keystore ...`)

### Known platform behaviours

| Platform | Quit button | Back button | Orientation |
|----------|-------------|-------------|-------------|
| Desktop  | ✅ shown    | ESC = pause | F11 fullscreen |
| Android  | ❌ hidden   | Hardware back = pause | Set in manifest |
| Web      | ✅ shown    | N/A         | Browser controls |

---

## Tuning the Game

All gameplay constants live in the `C` table at the top of `main.lua`:

```lua
C.fire.baseSpawnInterval  -- seconds between fire spawns
C.fire.spawnScaleFactor   -- how fast spawning accelerates over time
C.fire.damagePerTick      -- damage per fire touch
C.ai.weights              -- [chase, avoid, block, cluster, wait]
C.multikill.window        -- seconds for multi-kill detection
C.player.speed            -- armadillo movement speed
```

The `adapt()` function mutates these after each death based on player performance score (`fires extinguished / survival time`).

---

## Known Issues

- **Web fullscreen**: returning from fullscreen malforms the canvas (love.js limitation, out of scope)
- **Web sound**: programmatic sound generation crashes love.js/WASM — use pre-baked `.wav` files (already solved, see above)
- **Android orientation**: `conf.lua` orientation hint only works on iOS; Android requires manifest setting

---

## Built With

- [LÖVE 11.5](https://love2d.org/) — game framework
- [love.js](https://github.com/Davidobot/love.js) — web export
- Lua — language
