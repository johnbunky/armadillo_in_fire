# push-demo ??? Agent Briefing

## Project Goal
two balls, player pushes second ball

## Tech Stack
Love2D + Lua
 
## Current Status
Complete core game with modular structure, physics, shadows, audio, and fire damage system. Features fire spawning using predictive player movement (0.28s ahead, 65px distance), red ball fire extinguishing with stain creation, player health system with damage/regeneration, and game over mechanics.

## Open Tasks
- [x] task 5: Add damage indicator visual feedback
- [x] task 4.2: Replace coin collection sounds with fire damage/extinguish sounds
- [x] task 4.1:  Add fire-related sound effects (crackling, damage, extinguish)
- [x] could you take a look whats wrong with the ui.lua
- [x] could you pass throw the whole project and fix merge conflicts properly

### Current State Analysis:

### Fire System Conversion Tasks:

**4. Update Audio System:**
- Add fire-related sound effects (crackling, damage, extinguish)
- Replace coin collection sounds with fire damage/extinguish sounds

**5. Update UI System:**
- Add damage indicator visual feedback

**6. Menu System Implementation (existing plan):**
- Create menu system with navigation between screens
- Add settings, help, and main menu screens
- Integrate menu state management

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
- Converted system from coins to fires with static spawning behavior and predictive positioning
- Implemented player damage system with health (100 max), fire damage (20 per hit), regeneration (10/sec), and game over mechanics
- Added fire extinguishing by red ball contact with stain creation and dissolution
- Removed fire movement/chasing behavior to keep fires static after spawn

## Known Issues

## Feel Notes ??? only human writes here

- Earlier iterations focused on physics, friction, collision systems, visual improvements, sounds, shadows, and background color adjustments
- [2026-03-08 16:51:05] game started withou errors, for some reasond fires are move and cover the player, stain finction works ok
- [2026-03-08 17:07:14] there is ony there fire, probably it would be great to icrease fire?s gradualy during playtime
- [2026-03-08 17:14:15] it works well, it would be ok to remove shadows from fire, and change fire shape from circle to triangle

## Project Structure
  conf.lua
  gamestate.lua
  main.lua
  src\audio.lua
  src\ball.lua
  src\coin.lua
  src\fire.lua
  src\gamestate.lua
  src\physics.lua
  src\stain.lua
  src\ui.lua


- [2026-03-09 13:16:53] stain´s shape should be elips not circle
