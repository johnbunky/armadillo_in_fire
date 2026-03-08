# push-demo — Agent Briefing

## Project Goal
two balls, player pushes second ball

## Tech Stack
Love2D + Lua
 
## Current Status
Complete core game with modular structure, physics, shadows, audio, and coin collection system

## Open Tasks
- [x] could you create .gitignore and fill that by all required love2d lua game as well as .log and history.txt etc
- [x] could you make backgound brighter, shadows are not visible now

### Plan: it wouls be greate to add a main menu before the game with all guides and settings [2026-03-06 15:20:07]
1. Create src/menu.lua with menu system supporting navigation between different screens (main, settings, help)
2. Add menu state to GameState with states: "menu", "settings", "help", "playing"
3. Implement main menu screen with "Play", "Settings", "Help", "Quit" options
4. Implement settings screen with audio toggle, volume slider, and key binding display
5. Implement help screen with complete game instructions and controls guide
6. Add menu navigation controls (arrow keys, enter, escape) to main.lua keypressed function
7. Create menu background and visual styling with consistent theme
8. Integrate menu system into main.lua game loop (update/draw based on current state)
9. Add smooth transitions between menu screens and game start
10. Test all menu navigation paths and ensure proper state management

## Decisions Made
- Created modular project structure with separate Ball, Coin, Physics, GameState, and UI modules
- Implemented physics-based collision with impulse calculations and restitution
- Added friction/damping system with different values for player vs pushable balls
- Red ball has zero friction and reflects off walls with 0.8 speed reduction
- Added shadow rendering system for depth perception
- Created audio system with sound generation fallbacks
- Implemented coin collection system with 2-second respawn timer
- Added volume control and mute toggle functionality

## Known Issues

## Feel Notes — only human writes here

- Earlier: Multiple iterations on physics, friction, and collision systems
- [2026-03-06 13:23:26] it works well, thank you
- [2026-03-06 13:39:22] game works well, but shadows are missing
- [2026-03-06 13:42:09] game works well, but shadows and sounds are missing
- [2026-03-06 15:16:59] sounds and shadows are work well
- [2026-03-06 15:26:48] background color is ok

- [2026-03-06 15:38:47] oops, the background color is too dark again
