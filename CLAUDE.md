# push-demo вЂ” Agent Briefing

## Project Goal
two balls, player pushes second ball

## Tech Stack
Love2D + Lua
 
## Current Status
Complete core game with modular structure, physics, shadows, audio, and AI coin behavior system. Features predictive coin spawning, player detection, red ball avoidance, and slow repositioning movement.

## Open Tasks
- [x] could you remove movment ability of fire, it chase the plyer now
- [x] task 1.1: - Modify gamestate.lua to use Fire objects instead of Coin objects
- [x] coins spawn using evolved strategy: predict player movement 0.28s ahead, spawn coin 65px from predicted position, avoid red ball by 130px minimum distance when choosing spawn point. Coins stay static after spawning, no movement
 
### Current State Analysis:
- ФЈа Fire class exists with flickering animation and player tracking behavior
- ФЈа Stain class exists with dissolve animation over 3 seconds
- ФЈа Background is already light green (grass-like)
- ФЈа Core game mechanics (player ball, red pushable ball) are working
- ФШо Game still uses coin collection system instead of fire system
- ФШо No damage system for player health
- ФШо No fire extinguishing mechanics
- ФШо UI still shows coin-related text

### Fire System Conversion Tasks:

**1. Replace Coin System with Fire System:**
- Modify gamestate.lua to use Fire objects instead of Coin objects
- Update spawn logic to create Fire instances with existing predictive positioning
- Change collision detection from coin collection to fire damage
- Add red ball fire extinguishing collision detection

**2. Implement Player Damage System:**
- Add health/damage properties to player ball
- Create damage system when player touches fire
- Add health regeneration over time
- Implement game over condition when health reaches zero

**3. Implement Fire Extinguishing Mechanics:**
- Add collision detection between red ball and fire
- Replace fire with stain when extinguished by red ball
- Add stain management system to gamestate
- Update stain lifecycle (3 second dissolve as already implemented)

**4. Update Audio System:**
- Add fire-related sound effects (crackling, damage, extinguish)
- Replace coin collection sounds with fire damage/extinguish sounds

**5. Update UI System:**
- Replace coin counter with player health display
- Update instruction text to reflect fire mechanics
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

## Known Issues

## Feel Notes вЂ” only human writes here

- Earlier iterations focused on physics, friction, collision systems, and visual improvements
- [2026-03-06 15:16:59] sounds and shadows are work well
- [2026-03-06 15:26:48] background color is ok
- [2026-03-06 15:38:47] oops, the background color is too dark again

- [2026-03-08 16:51:05] game started withou errors, for some reasond fires are move and cover the player, stain finction works ok

## Project Structure
  conf.lua
  main.lua
  src\audio.lua
  src\ball.lua
  src\coin.lua
  src\fire.lua
  src\gamestate.lua
  src\physics.lua
  src\stain.lua
  src\ui.lua
