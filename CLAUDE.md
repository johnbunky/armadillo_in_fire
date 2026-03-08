# push-demo — Agent Briefing

## Project Goal
two balls, player pushes second ball

## Tech Stack
Love2D + Lua
 
## Current Status
Complete core game with modular structure, physics, shadows, audio, and AI coin behavior system. Features predictive coin spawning, player detection, red ball avoidance, and slow repositioning movement.

## Open Tasks
- [x] coins spawn using evolved strategy: predict player movement 0.28s ahead, spawn coin 65px from predicted position, avoid red ball by 130px minimum distance when choosing spawn point. Coins stay static after spawning, no movement

### Plan: let's keep the existing menu plan, and add one more game flow change it should be fire instead of coins, and fire damages the player, red ball stopped a fire, back ground should be light green, like a grass, after fire stopped by red ball there is a stain on this place that dissapear in some seconds, may be dissole [2026-03-08 10:37:38]
2. Rename Coin class to Fire class with red/orange coloring
3. Update Fire class to have flame-like visual effects (flickering animation)
4. Add damage system to player ball when touching fire
5. Modify collision logic so red ball extinguishes fire instead of player collecting
6. Create Stain class for marks left after fire extinguishing
7. Add stain spawning when fire is extinguished by red ball
8. Implement stain dissolve animation over time
9. Update UI text to reflect fire mechanics instead of coin collection
10. Update audio effects to match fire theme (crackling, extinguish sounds)
11. Modify gamestate to track fire/stain spawning and management
12. Add player health/damage display to UI

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
- Implemented AI coin behavior with player detection (150px), red ball avoidance (130px), and slow repositioning (speed 20)
- Added predictive coin spawning using 0.28s movement prediction, 65px spawn distance, 1.95s delay, 58% clustering chance
- Added volume control and mute toggle functionality
- Set grass-like light green background (0.6, 0.8, 0.4) for visual theme
- Created comprehensive .gitignore for Love2D projects

## Known Issues

## Feel Notes — only human writes here

- Earlier iterations focused on physics, friction, collision systems, and visual improvements
- [2026-03-06 15:16:59] sounds and shadows are work well
- [2026-03-06 15:26:48] background color is ok
- [2026-03-06 15:38:47] oops, the background color is too dark again