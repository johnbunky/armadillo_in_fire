# push-demo ??? Agent Briefing

## Project Goal
two balls, player pushes second ball

## Tech Stack
Love2D + Lua
 
## Current Status
Complete core game with modular structure, physics, shadows, audio, and fire damage system. Features fire spawning using predictive player movement (0.28s ahead, 65px distance), red ball fire extinguishing with stain creation, player health system with damage/regeneration, game over mechanics, fire-themed audio system, and comprehensive damage visual feedback including floating damage numbers and health bar indicators.

## Open Tasks
- [x] nothing happens if click on start game on main manu, expected result game starts
- [x] task 6.3: Integrate menu state management
- [x] it looks like you�ve already made all required changes but there is an issue no file, could you create the reqired one and complet the menu implementation
- [x] task 6.1: Create menu system with navigation between screens
**6. Menu System Implementation (existing plan):**
- Create menu system with navigation between screens
- Add settings, help, and main menu screens
- Integrate menu state management

### Plan: create and add unit and integrations tests in the tests folder [2026-03-09 14:03:58]
1. Create tests folder structure and test configuration file
2. Create unit tests for Audio module (sound generation, volume control, enable/disable)
3. Create unit tests for Ball module (creation, movement, health system, damage)
4. Create unit tests for Fire module (creation, animation, flickering)
5. Create unit tests for Physics module (collision detection, boundary handling)
6. Create unit tests for Stain module (creation, dissolving animation)
7. Create unit tests for UI module (health bar calculations, status displays)
8. Create integration tests for fire damage system (ball-fire collision → damage → audio)
9. Create integration tests for fire extinguishing system (pushball-fire collision → extinguish → stain creation → audio)
10. Create integration tests for ball physics system (movement, collision, boundary bounce with audio)
11. Create test runner script to execute all tests and generate reports
12. Create mock/stub system for Love2D functions used in tests
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
- Fixed UI module with proper module structure and return statement
- Removed dependency on separate GameState class and integrated game state logic directly into main.lua
- Replaced coin collection sounds with fire-themed audio (playFireExtinguish() and playFireDamage())
- Enhanced damage indicators with floating damage numbers, pulsing health bar, screen-edge damage overlay, and critical health warnings

## Known Issues

## Feel Notes ??? only human writes here

- Earlier iterations focused on physics, friction, collision systems, visual improvements, sounds, shadows, and background color adjustments
- [2026-03-08 16:51:05] game started withou errors, for some reasond fires are move and cover the player, stain finction works ok
- [2026-03-08 17:07:14] there is ony there fire, probably it would be great to icrease fire?s gradualy during playtime
- [2026-03-08 17:14:15] it works well, it would be ok to remove shadows from fire, and change fire shape from circle to triangle
- [2026-03-09 13:16:53] stain?s shape should be elips not circle

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

- [2026-03-09 14:35:09] main menu looks amaizing, unforutately start game doesn�t work
