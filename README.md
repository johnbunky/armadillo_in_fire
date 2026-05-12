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

> **Windows gotcha:** the global `love.js` shim won't run due to `.js` file association. Call the entry point directly:
> ```bash
> node "C:\Users\yourname\AppData\Roaming\npm\node_modules\love.js\index.js" ...
> ```

### Build and test locally

```bash
# 1. Pack the game into a .love file (must be zip format, not 7z)
Remove-Item mygame.love
7z a -tzip mygame.love main.lua conf.lua src assets

# 2. Build web output
node "C:\Users\yourname\AppData\Roaming\npm\node_modules\love.js\index.js" mygame.love output_folder -t "YourGameTitle"

# 3. IMPORTANT: restore patched index.html (the build overwrites it)
copy index_patched.html output_folder\index.html

# 4. Serve locally (needs COOP/COEP headers for SharedArrayBuffer)
cd output_folder
python3 server.py
# open http://localhost:3000
```

### server.py (required for local testing)

Save this as `output_folder/server.py`:

```python
import http.server, socketserver

class Handler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        super().end_headers()

with socketserver.TCPServer(("", 3000), Handler) as httpd:
    print("Serving at http://localhost:3000")
    httpd.serve_forever()
```

> itch.io sends these headers automatically — this is only needed for local smoke testing.

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
- Enable **SharedArrayBuffer** in the embed options (required)

---

## Android Build (command-line, no Android Studio)

### Prerequisites

Install via [Scoop](https://scoop.sh/):

```bash
scoop bucket add java
scoop install java/openjdk
scoop install apktool
scoop install uber-apk-signer
```

Verify:
```bash
java --version
apktool --version
uber-apk-signer --version
```

### 1. Download the love-android prebuilt APK

```bash
curl -L -o love.apk "https://github.com/love2d/love-android/releases/download/11.5a/love-11.5-android-embed.apk"
```

### 2. Decompile

```bash
apktool d love.apk -o love_decompiled
```

### 3. Drop your game in

```bash
copy armadillo_in_fire.love love_decompiled\assets\game.love
```

### 4. Edit AndroidManifest.xml

Open `love_decompiled\AndroidManifest.xml` and make these changes:

| What | From | To |
|------|------|----|
| `package` attribute | `org.love2d.android` | `com.yourname.yourgame` |
| `<permission>` name | `org.love2d.android.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | `com.yourname.yourgame.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` |
| `<uses-permission>` name | `org.love2d.android.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | `com.yourname.yourgame.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` |
| `<provider>` authorities | `org.love2d.android.androidx-startup` | `com.yourname.yourgame.androidx-startup` |
| `android:label` | `LÖVE for Android` | Your game title |

> **Do not change** `android:name="org.love2d.android.GameActivity"` — this points to compiled Java code inside the APK.

### 5. Recompile

```bash
apktool b love_decompiled -o armadillo_unsigned.apk
```

### 6. Create a keystore (first time only)

```bash
keytool -genkey -v -keystore armadillo.keystore -alias armadillo -keyalg RSA -keysize 2048 -validity 10000
```

> **Keep this file safe and backed up.** You need the same keystore for every future update — losing it means you can't update the Play Store listing.

### 7. Sign the APK

```bash
uber-apk-signer -a "C:\full\path\to\armadillo_unsigned.apk" --ks "C:\full\path\to\armadillo.keystore" --ksAlias armadillo --ksPass YOURPASSWORD --ksKeyPass YOURPASSWORD -o "C:\full\path\to\output"
```

> Use full absolute paths — relative paths have issues on Windows with uber-apk-signer.

Output file will be named `armadillo_unsigned-aligned-signed.apk`. Rename it:

```bash
rename armadillo_unsigned-aligned-signed.apk armadillo_in_fire.apk
```

### 8. Upload to Google Play

1. Go to [play.google.com/console](https://play.google.com/console) ($25 one-time registration fee)
2. Create app → fill in title, description, category
3. Add screenshots (at least 2) and a feature graphic (1024×500px)
4. Complete the content rating questionnaire
5. Go to **Production** → **Releases** → upload `armadillo_in_fire.apk`
6. Submit for review (typically 1–3 days)

---

## Known Issues

- **Web fullscreen**: returning from fullscreen malforms the canvas (love.js limitation, out of scope)
- **Web sound**: programmatic sound generation crashes love.js/WASM — use pre-baked `.wav` files (already solved, see above)
- **Android orientation**: `conf.lua` orientation hint only works on iOS; Android requires manifest setting
- **Play Store**: may prefer `.aab` over `.apk` in future — the apktool approach produces APK only

---

## Platform Behaviour Summary

| Platform | Quit button | Back button | Orientation |
|----------|-------------|-------------|-------------|
| Desktop  | ✅ shown    | ESC = pause | F11 fullscreen |
| Android  | ❌ hidden   | Hardware back = pause | Set in manifest |
| Web      | ✅ shown    | N/A         | Browser controls |

---

## Built With

- [LÖVE 11.5](https://love2d.org/) — game framework
- [love.js](https://github.com/Davidobot/love.js) — web export
- Lua — language
