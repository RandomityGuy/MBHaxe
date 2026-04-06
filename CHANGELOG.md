# 1.1.13
This update brings feature and bugfix parity with the latest MBP version:
- Fixed a ton of bugs that were fixed in MBP since the last update.
- Updated the options menu to have more meaningful options and add more options for touch controls.
- Added Import and Export Progress to Options menu to transfer game progress between devices.
- Made the game files to be case insensitive to allow running the game on case sensitive filesystems without issues.
- Improved camera sensitivity on touch devices.
- Implemented camera centering for touch controls when free look is disabled.
- Various performance improvements and crash fixes.
- Implemented console cheat commands. DefaultMarble.attribute = value; to change marble attributes.
- Fixed a bug with the timer when playing a replay.
- Fixed gravity changes not rewinding properly.

# 1.1.12
This update fixes the following bugs:
- Fixed marble phasing through interiors when going too fast
- Fixed jittery interaction with marble and moving platforms

# 1.1.11
This update brings the following fixes:
- Minor UI changes.
- Optimized rewind to use memory better.
- Fixed a handful of memory leaks.
- Match with MBG Collision code.

# 1.1.10
This update brings the following fixes:
- Fixed marble finish animation not working.
- Fixed camera movement at varying FPS and sensitivities.
- Minor performance improvements.

# 1.1.9
This update fixes the following bugs:
- Fixed bugs caused by rewinding past the level start.
- Fixed crash caused by traplaunch.
- Removed the ability to rewind if you finished the level.
- Fixed a bug concerning moving platform collisions.
- Made moving platforms rewind correctly in case of traplaunches.

# 1.1.8
This is the first version to support android!
This update adds the following features and bugfixes:
- Adds Rewind feature. Open options to enable rewind and configure its settings!
- Improved traplaunches, they should now be more easily doable.
- Minor physics fixes.
- Fixed broken finish pads

# 1.1.7
This update brings the following changes:
- Added controller support.
- Added support to load and play custom levels. (Native only)
- Improved replay UX flow.
- Improved marble physics a bit.
- Fixed Tornado rendering.
- Fixed some collision bugs.

# 1.1.6
This release backports the fixes from MBP:
This is the first build of MBHaxe Gold that has Mac support.
Changelog:
- FOV is now based on horizontal FOV instead of vertical, matching with original MB.
- Fixed the marble getting stuck in the corners.
- Fixed broken resolution after pressing the back button in Retina display.
- Fixed wrong level order in Intermediate.

# 1.1.5
This release backports the fixes from MBP:
This is the first build of MBHaxe Gold that has Mac support.
Changelog:
- Reduced lag caused by end pad.
- Fixed inactive button hover sounds.
- Fixed OOB animation timings.
- Added HighDPI/Retina support.
- Fixed the color bugs regarding text input.
- Minor performance and physics improvements.
- Fixed tornado rendering.

# 1.1.4
This release backports the fixes from MBP:
- Fixed Pad animations not working
- Fixed bugs relating to powerup pickup on respawn.
- Fixed marble not using the hitbox of the rotated hitbox for item pickups.
- Marble finish animation now matches more closely with the original.
- Fixed camera keys not working.
- Added keyboard shortcuts to certain buttons on certain dialog boxes.
- Fixed lag caused by GJK/Startpad/Endpad.
- Fixed being able to press the end game buttons while typing the name. The input box will be focused.
- Fixed option sliders not updating values

# 1.1.3
This update brings the following changes:
- Updated Particle Rendering (improved performance)
- Fixed lot of marble physics bugs, they should now be smoother.
- Minor performance improvements

# 1.1.2
This update brings the following changes:
- Added basic state based replays.
- Support for asynchronous resource loading on Web target.

# 1.1.0
Touch Controls and Performance Improvements Update:
- Updated the engine to the latest version
- Added touch controls on the web version when it is loaded on mobile, along with its settings.
- Improved level loading speed on web version and reduced WebGL crashes
- Improved font rendering
- Fixed tornado rendering bug
- Minor performance and stability improvements overall

# 1.0.0
Initial release, windows version.