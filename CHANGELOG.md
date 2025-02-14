# 1.7.1
This update brings the following bugfixes:
- Fixed a crash when the marble goes out of bounds.
- Fixed the FPS limiter not limiting rendered frames per second.
- Fixed scores not being sent in certain cases.

# 1.7.0
It's the fabled Leaderboards update!
Leaderboards have been implemented for all the levels with automatic replay uploading for official levels as well as watching top replays. Additionally, segregation has been made to allow switching between rewind and non-rewind scores on the leaderboards.

Changes:
- Added an FPS limiter in the settings.
- Added custom friction support as well as custom marble attributes. Now levels can modify the marble's physics parameters to their liking.
- Improved level select persistence. Now your last chosen level will be displayed on quitting or finishing a level instead of last level in a category.
- Improved the Gem Hunt algorithm to match closer to PlatinumQuest's.
- Trigger detection now matches with the original game.
- Camera is now smoothened.
- Fixed camera not pointing at gems after respawn in Multiplayer.
- Fixed Superspeed powerup sometimes throwing you in the wrong direction in Multiplayer.
- Fixed the marble being wonky at times in replays.
- Fixed an interaction with Random powerup giving Time Travels.
- Fixed some collision issues with moving platforms.

# 1.6.1
This update fixes the following bugs:
- Fixed a crash when there are more players than spawnpoints in multiplayer.
- Fixed minor UI bugs with kicking and player list.
- Prevent timing out of players who are still loading the level.
- Fixed sort order of two multiplayer levels.
- Attempted to improve performance when someone joins mid-game.
- Touch Controls: Pressing pause now releases the joystick.

# 1.6.0
A big update! Bringing in the cross platform multiplayer the way it was meant to be played!
Please note that it is always and always recommended to download the native client for unlocked FPS and higher performance.
- Added cross platform multiplayer, the Online button is now unlocked.
  - Gem Hunt Free-for-all only, no other game modes are present.
  - Server authoritative marble physics and rollback netcode for all gameplay elements - including moving platforms.
  - Up to 8 players due to platform technical limitations.
  - Seamless multiplayer custom levels integration through Marbleland.
  - Spectator mode is implemented but lasts until the end of match.
  - Four PlatinumQuest levels that were present in MBP multiplayer have been added along with their shaders.
  - Added the Ability to toggle between old spawns and new spawns for certain multiplayer maps.
  - Added Competitor Mode:
    - A new gem spawn will happen automatically after a certain duration depending on number of gems picked up.
    - Reduced Mega Marble duration.
    - Only Ultra Blasts can affect marbles.
    - Fixed starting point.
- Touch controls improvements:
  - Configure visibility of On-Screen Controls
  - Configure behavior of buttons acting as camera joystick by altering Button Camera Factor
  - Configure your camera sensitivity and swipe extent.
  - Improved touch camera sensitivity a bit.
  - Added Dynamic Joystick for Touch Controls.
- Added support for iOS for the web version.
- Improved Controller support for Android.
- Optimized the game to run at much higher framerates.
- Improved marble shadow.
- Fixed certain customs missing interiors/textures.
- Fixed marble collision at varying radii.
- Fixed Super Speed throwing you in the wrong direction.

# 1.5.4
This update fixes the following bugs:
- Updated Marbleland support. New levels will now automatically show up.
- Implement "Latest" and "Alphabetical" sorting for Marbleland customs.
- Optimized rewind to use memory better.
- Fixed a handful of memory leaks.
- Match with MBG Collision code.

# 1.5.3
This update fixes the following bugs:
- Slightly improved marble cubemaps.
- Fixed camera movement for varying FPS and sensitivities.
- Fixed rolling sound bug.

# 1.5.2
- Updated Marbleland integration link to the new site.

# 1.5.1
This update fixes the following bugs:
- Fixed a bug concerning moving platform collisions.
- Made moving platforms rewind correctly in case of traplaunches.

# 1.5.0
This update brings the following big changes:
- Added Rewind capabilities. Open options to configure it.
- Added capability to play locally installed custom levels. Install your customs in platinum/data/missions.
- Improved traplaunches, now they should be much more easier to do.
- Buffed nuke a bit, hold jump key to make it blast much stronger.
- Minor physics improvements.
- Minor performance improvements.

# 1.4.0
This update adds all the playable MBG, MBP, MBU custom levels via Marbleland integration. Play the entire custom level archive without manually installing with, with a single click.
- Added controller support. (Thanks thearst3rd)
- Improved replay saving flow.
- Improved marble physics a bit.
- Cleaned up some UI.
- Fixed collision detection bugs.
- Fixed various graphical bugs.
- Fixed item hitboxes being too small. 
# 1.3.3
This update addresses the following issues:
- FOV is now based on horizontal FOV instead of vertical, matching with- original MB.
- Fixed the marble getting stuck in the corners.
- Fixed black screen on opening the game for the first time on MacOS

# 1.3.2
This is the first build of MBHaxe Platinum that has Mac support.
- MBU interior shaders now match more closely to those of MBU in Xbox.
- Added Console for debug purposes. Press Tilde ~ to bring it up.
- Added replay browser for native.
- Reduced lag caused by end pad.
- Fixed inactive button hover sounds.
- Fixed OOB animation timings.
- Added HighDPI/Retina support.
- Fixed the color bugs regarding text input.
- Minor graphical changes to match original.
- Minor performance and physics improvements.
- Fixed tornado rendering.

# 1.3.1
This release fixes a lot of bugs that were reported and adds in minor improvements:
- Fixed Pad animations not working
- Fixed bugs relating to powerup pickup on respawn.
- Fixed marble not using the hitbox of the rotated hitbox for item pickups.
- Marble finish animation now matches more closely with the original.
- Fixed camera keys not working.
- Added keyboard shortcuts to certain buttons on certain dialog boxes.
- Timer now becomes green on finishing, to match original.
- Fixed double click sound on selecting level category.
- Hypercube now uses MBG gameplay logic.
- Added Time Travel Bonus messages to HUD.
- Fixed lag caused by GJK/Startpad/Endpad.
- Fixed being able to press the end game buttons while typing the name. The- input box will be focused.
- Fixed option sliders not updating values

# 1.3.0
- Added Marble Blast Ultra levels as per Platinum.
- Added Ultra Marbles as per Platinum and their shaders.
- Added shaders for Ultra levels closely matching original MBU. (This may- lag mobile devices)
- Fixed lot of marble physics bugs, they should now be smoother.
- Minor performance improvements.
- Added restart button to touch controls.

# 1.2.0
- Implemented most Marble Blast Platinum 1.7.42 (except Ultra)
- Marble reflections
- Optimized resource loading and performance
