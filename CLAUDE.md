# push-demo ‚Äî Agent Briefing

## Project Goal
two balls, player pushes second ball

## Tech Stack
Love2D + Lua
 
## Current Status
In progress

## Open Tasks
- [x] task 8: ball moves too slow and doesnt respond to repeated pushes, also Love2D opens twice on start
- [x] task 7
- [x] task 6
- [x] 5. Implement collision detection between the two balls
- [x] task 3 and 4: player ball keyboard controls, second pushable ball, ESC to quit, instructions overlay
- [x] task 2: implement Ball class with position, radius, color and rendering
- [x] task 1: create main.lua with basic Love2D window and game loop

### Plan: two balls, player able to push second ball [2026-03-05 20:25:51]
1. Create a basic game window with a rendering system
2. Implement a Ball class with position, radius, and rendering
3. Create the first ball (player ball) with keyboard input controls for movement
4. Create the second ball (pushable ball) at a different starting position
5. Implement collision detection between the two balls
6. Add physics for the second ball to respond to pushes from the player ball
7. Add basic friction/damping to make ball movement feel natural
8. Test and refine the pushing mechanics for smooth gameplay

## Decisions Made

## Known Issues

## Feel Notes  ‚Üê only human writes here

- [2026-03-05 20:31:15] game is started, background is nice, there is no and game here yet

- [2026-03-05 20:37:48] two ball are present, but instruction is missing, and esc doesn?t work

- [2026-03-05 20:49:01] two balls and instruction are present, esc and keyboard input controls work

- [2026-03-05 21:00:20] it works second ball responds to push, but it moves too slow, and doesn¥t respond to another push

- [2026-03-05 21:10:33] yep it works but ball move to slow, one more thing, for some reason love starts twice, it¥s opened closed and open again 
