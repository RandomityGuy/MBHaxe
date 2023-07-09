Extract the game to ~/Applications or /Applications.
It will say "Unverified Developer". Go to System Preferences (or System Settings) > Security & Privacy > Click open Anyway

If you get error saying that the app is "damaged,"
please remove the quarantine flag.

sudo xattr -r -d com.apple.quarantine "MarbleBlast Ultra.app"