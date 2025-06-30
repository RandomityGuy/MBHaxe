# 1.2.3
This update brings the following changes:
- Balanced out the Rating curves for a lot of levels.
- Added a Rating column to the Leaderboards.
- Added Global Player Leaderboards.
- Added a new option to emulate modded controller inputs for Controller users.
- Added a new menu to modify the controller bindings.
- Added support for controllers for list navigation.
- Tweaked the controller camera sensitivity.
- Fixed a friction material having incorrect values.
- Fixed a bug with the timer when playing a replay.
- Fixed a bug with the server list showing an incorrect number of players.

# 1.2.2
This update brings the following changes:
- Added Leaderboards for Gem Hunt levels.
- Added an option to change the quick respawn key when out of bounds.
- Changed Replay Center's UI a bit.
- Fixed buggy collisions with Trapdoors.
- Fixed a bug where you'd get stuck after restarting a certain number of times in Singleplayer Gem Hunt.

# 1.2.1
This update brings the following bugfixes:
- Fixed a crash when the marble goes out of bounds.
- Fixed vsync being a little laggy.
- Fixed scores not being sent in certain cases.

# 1.2.0
It's the fabled Leaderboards update!
Leaderboards have been implemented for all the levels with automatic replay uploading for official levels as well as watching top replays. Additionally, segregation has been made to allow switching between rewind and non-rewind scores on the leaderboards.

Changes:
- Added a few more custom levels in the Multiplayer custom level list as well as bouncy floor support which some customs needed.
- Added custom friction support as well as custom marble attributes. Now levels can modify the marble's physics parameters to their liking.
- Fixed Superspeed powerup sometimes throwing you in the wrong direction in Multiplayer.
- Fixed the marble being wonky at times in replays.
- Fixed certain maps not being rendered correctly.
- 
# 1.1.3
This update brings the following changes:
- Added IOS support for the Web version of the game.
- Added Dynamic Joystick for Touch Controls.
- Improved server list with status.
- Improved marble smoothing in Multiplayer.
- Increase chat character limit.
- Now you will be prompted to set display name if the name is not valid.
- Fixed marbles glitching out in Marble Picker.
- Fixed server crash caused when players try to join a game more than 8 times.
- Fixed trapdoor not having correct duration.
- Minor performance improvement.

# 1.1.2
This update fixes the following critical issue:
- Fixed persistent jitter when you are not the host in Multiplayer.

# 1.1.1
This update brings the following changes:
- Implemented Chat: Non-Mobile only for now, press T to bring up chat in Multiplayer.
- Added a new Touch Options Page.
  - Configure visibility of On-Screen Controls
  - Configure behavior of buttons acting as camera joystick by altering Button Camera Factor
  - Configure your camera sensitivity and swipe extent.
- Improved Controller support for Android.
- Improved Touch Camera sensitivity a bit.
- Tried to improve network latency.
- Fixed minor UI bugs.
- Fixed Super Speed throwing you in the wrong direction.
- Fixed Out of Bounds ceiling.
- Fixed Blast force of Mega Marble.

# 1.1.0
After all these years, Marble Blast Online is finally back!
Implemented as the Multiplayer update to Marble Blast Ultra Haxe Port.
Multiplayer is *fully* cross platform allowing you to join and host matches across all the following platforms: Windows, Mac, Web, Android.

Changelog:
- Added Cross Platform Multiplayer
	- Server Browser, Join and Hosting, Invite Code support.
	- Multiplayer Customs Browser
	- Related Multiplayer Achievements are added.
- Optimized the game to run at much higher frame rates.
- Matched marble shadow to match with MBU.
- Fixed a bug regarding marble rotations when the game is playing at low fps.
- Fixed a minor shader bug with tiles.

# 1.0.2
This update fixes the following bugs.
- Optimized rewind to use memory better.
- Fixed a handful of memory leaks.
- Match with MBG Collision code.

# 1.0.1
This update fixes the following bugs:
- Updated the skyboxes for specific levels.
- Fixed a softlock caused by exiting a level to main menu while recording.
- Fixed achievement popup at wrong times.
- Fixed camera orientation bug when changing gravity.
- Fixed moving platform timings.
- Fixed some UI issues for higher resolutions.
- Fixed a softlock caused by running out of time while OOB in Gem Hunt.

# 1.0.0
Initial Release of Marble Blast Ultra Haxe Port.  
Differences from OpenMBU/MBU Xbox:
- No Multiplayer support, for the forseeable future.
- No leaderboards support yet, not until OpenMBU gets leaderboards.
- Replay recording and watching support, even for Gem Hunt.
- Rewind TAS support.
- Minor shader differences.
- Options may differ slightly.
Please report any bugs.