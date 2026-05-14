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

## Android Build (APK for sideloading / ADB testing)

Quick path to get an APK on your device without Android Studio. Not suitable for Play Store (which requires AAB) but useful for local testing.

### Prerequisites

```bash
scoop bucket add java
scoop install java/openjdk
scoop install apktool
scoop install uber-apk-signer
```

### Steps

```bash
# 1. Download the love-android prebuilt APK
curl -L -o love.apk "https://github.com/love2d/love-android/releases/download/11.5a/love-11.5-android-embed.apk"

# 2. Decompile
apktool d love.apk -o love_decompiled

# 3. Drop your game in
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

```bash
# 5. Recompile
apktool b love_decompiled -o armadillo_unsigned.apk

# 6. Create keystore (first time only)
keytool -genkey -v -keystore armadillo.keystore -alias armadillo -keyalg RSA -keysize 2048 -validity 10000

# 7. Sign — use full absolute paths, relative paths fail on Windows
uber-apk-signer -a "C:\full\path\to\armadillo_unsigned.apk" --ks "C:\full\path\to\armadillo.keystore" --ksAlias armadillo --ksPass YOURPASSWORD --ksKeyPass YOURPASSWORD -o "C:\full\path\to\output"

# 8. Rename
rename armadillo_unsigned-aligned-signed.apk armadillo_in_fire.apk

# 9. Install via ADB
adb install armadillo_in_fire.apk
```

---

## Android Build (AAB for Google Play)

Play Store requires `.aab` format. This build compiles the full LÖVE engine from source using love-android.

### Prerequisites

Install via [Scoop](https://scoop.sh/):

```bash
scoop bucket add java
scoop install java/temurin17-jdk   # must be exactly JDK 17
scoop install android-clt
```

> **JDK must be exactly 17** — not 21, not 26. The love-android README is explicit about this.

Set Java 17 as active (required each session — set JAVA_HOME permanently to avoid repeating):

```bash
set JAVA_HOME=%USERPROFILE%\scoop\apps\temurin17-jdk\current
set PATH=%JAVA_HOME%\bin;%PATH%
java -version   # confirm: openjdk version "17.x.x"
```

Accept Android SDK licenses (first time only):

```bash
%USERPROFILE%\scoop\apps\android-clt\current\cmdline-tools\cmdline-tools\bin\sdkmanager.bat --licenses
```

### 1. Clone love-android with submodules

```bash
git clone --recurse-submodules https://github.com/love2d/love-android
cd love-android
```

> If you already cloned without submodules:
> ```bash
> git submodule sync --recursive
> git submodule update --init --force --recursive
> ```
> Missing submodules cause `org.libsdl.app does not exist` errors.

### 2. Drop your game in

```bash
mkdir app\src\main\assets
copy path\to\armadillo_in_fire.love app\src\main\assets\game.love
```

### 3. Configure gradle.properties

Edit `gradle.properties`:

```properties
app.name=Armadillo in Fire
app.application_id=com.yourname.armadilloinfire
app.orientation=sensorLandscape   # allows both landscape orientations
app.version_code=1
app.version_name=1.0
# comment out app.name_byte_array if present
```

### 4. Reduce build size

In `app/build.gradle`, find the `ndk` block and set:

```groovy
ndk {
    abiFilters 'arm64-v8a'   // arm64 only — covers 95%+ of devices
    debugSymbolLevel 'none'  // removes debug symbols — cuts size from 120MB to ~13MB
}
```

### 5. Set Gradle and AGP versions

In `gradle/wrapper/gradle-wrapper.properties`:

```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.6-bin.zip
```

In root `build.gradle`:

```groovy
classpath 'com.android.tools.build:gradle:8.3.2'
```

> Gradle 8.13 + AGP 8.3.2 causes transform cache corruption. Gradle 8.6 + AGP 8.3.2 is the working combination.

### 6. Build the AAB

```bash
.\gradlew bundleEmbedNoRecordRelease
```

First build takes ~1 hour (compiling LÖVE engine C++ from source). Subsequent builds are ~30 seconds.

Output: `app/build/outputs/bundle/embedNoRecordRelease/app-embed-noRecord-release.aab`

### 7. Create a keystore (first time only)

```bash
keytool -genkey -v -keystore armadillo.keystore -alias armadillo -keyalg RSA -keysize 2048 -validity 10000
```

> **Keep this file safe and backed up.** You need the same keystore for every future update — losing it means you cannot update the Play Store listing ever again.

### 8. Sign the AAB

```bash
# Copy to a path without spaces first (jarsigner has issues with spaces in paths)
mkdir C:\temp
copy "app\build\outputs\bundle\embedNoRecordRelease\app-embed-noRecord-release.aab" C:\temp\armadillo.aab

jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 -keystore "C:\full\path\to\armadillo.keystore" C:\temp\armadillo.aab armadillo
```

### 9. Test on device via ADB

```bash
scoop install adb

# Enable on phone: Settings → About → tap Build Number 7 times
# Settings → Developer Options → USB Debugging ON

adb devices                                      # confirm device detected
adb install path\to\armadillo_in_fire.apk        # use APK for local testing (AAB not directly installable)
adb logcat | grep -i love                        # watch for errors
adb uninstall com.yourname.armadilloinfire       # clean uninstall before reinstall

# Take screenshots
adb shell screencap -p /sdcard/screen.png
adb pull /sdcard/screen.png
```

> AABs cannot be sideloaded directly — use a signed APK for local device testing, AAB for Play Store upload.

### 10. Upload to Google Play

> **Important:** Google Play accounts created after November 2023 require a closed test with 12 testers opted-in for 14 consecutive days before production access is granted. Plan for 3+ weeks before going live.

1. Go to [play.google.com/console](https://play.google.com/console) ($25 one-time registration fee)
2. Create app → set package name to match `app.application_id` in gradle.properties
3. Fill in store listing: title, short description (80 chars), full description, category
4. Add screenshots (at least 2) and a feature graphic (1024×500px, mandatory)
5. Complete content rating questionnaire
6. Go to **Internal testing** → **Create release** → upload `C:\temp\armadillo.aab`
7. Run closed test with 12+ testers for 14+ days to unlock production access
8. Apply for production → answer questions → submit for review (~7 days)

---

## Known Issues

- **Web fullscreen**: returning from fullscreen malforms the canvas (love.js limitation, out of scope)
- **Web sound**: programmatic sound generation crashes love.js/WASM — use pre-baked `.wav` files (already solved, see above)
- **Android orientation**: `conf.lua` orientation hint only works on iOS; Android requires `gradle.properties` setting
- **Gradle/Java version sensitivity**: love-android requires exactly JDK 17, Gradle 8.6, AGP 8.3.2 — any deviation causes build failures
- **Spaces in paths**: `jarsigner` has issues with paths containing spaces — always copy files to `C:\temp` before signing

---

## Platform Behaviour Summary

| Platform | Quit button | Back button | Orientation |
|----------|-------------|-------------|-------------|
| Desktop  | ✅ shown    | ESC = pause | F11 fullscreen |
| Android  | ❌ hidden   | Hardware back = pause | sensorLandscape (both ways) |
| Web      | ✅ shown    | N/A         | Browser controls |

---

## Built With

- [LÖVE 11.5](https://love2d.org/) — game framework
- [love-android](https://github.com/love2d/love-android) — Android port
- [love.js](https://github.com/Davidobot/love.js) — web export
- Lua — language
