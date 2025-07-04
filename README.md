# MBHaxe
A Haxe port of Marble Blast Gold, Ultra and Platinum, name subject to change.
The marble physics code was taken from [OpenMBU](https://github.com/MBU-Team/OpenMBU) along with my own collision detection code, game logic was partially from scratch and taken with permission from [Marble Blast Web Port](https://github.com/Vanilagy/MarbleBlast).  

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/H2H5FRTTL)  
Support Discord: https://discord.gg/GsmTVQQAhG
# Play
## Web Browser
The browser port supports touch controls, meaning it can be played on mobile devices.
### Marble Blast Gold: [Play](https://marbleblastgold.randomityguy.me/)
### Marble Blast Platinum: [Play](https://marbleblast.randomityguy.me/)
### Marble Blast Ultra: [Play](https://marbleblastultra.randomityguy.me/)
## Windows and Mac
### Marble Blast Gold: [Download](https://github.com/RandomityGuy/MBHaxe/releases/tag/1.1.12)
### Marble Blast Platinum: [Download](https://github.com/RandomityGuy/MBHaxe/releases/tag/1.7.1)
### Marble Blast Ultra: [Download](https://github.com/RandomityGuy/MBHaxe/releases/tag/1.2.3-mbu)
## Mac Instructions - Important
Put the .app file in either /Applications or ~/Applications in order to run it properly.  
You will also have to bypass Gatekeeper since the .app is not signed.
## Android
### Marble Blast Gold: [Download](https://github.com/RandomityGuy/MBHaxe/releases/download/1.1.12/MBHaxe-Gold.apk)
### Marble Blast Platinum: [Download](https://github.com/RandomityGuy/MBHaxe/releases/download/1.7.1/MBHaxe-Platinum.apk)
### Marble Blast Ultra: [Download](https://github.com/RandomityGuy/MBHaxe/releases/download/1.2.3-mbu/MBHaxe-Ultra.apk)

## Additional Features
- Cross Platform Multiplayer: Available in Ultra and Platinum. You can host and join multiplayer matches in any of these platforms: Windows, Mac, Web, Android.
- Replay System: You can record your run using the built in replay system and watch it later.  
- Rewind: You can rewind your marble by enabling rewind in the Options and holding down the rewind key (defaults to R). 
- Controller Support: Full controller support is added to Marble Blast Ultra, with incomplete support for the rest.
- Touch Controls: Available in the web (mobile) and android versions.

# Screenshots
<img src="https://imgur.com/Ncb4atl.png" width="640">
<img src="https://imgur.com/KQKUk0Y.png" width="640">
<img src="https://imgur.com/VnnrIt2.png" width="640">
<img src="https://imgur.com/lfLBKqO.png" width="640">
<img src="https://imgur.com/DN1A2Mf.png" width="640">
<img src="https://imgur.com/2UngOAy.png" width="640">
<img src="https://imgur.com/Jvfip72.png" width="640">
<img src="https://imgur.com/CS693zi.png" width="640">
<img src="https://imgur.com/iryo0AL.png" width="640">
<img src="https://imgur.com/vsuNqUi.png" width="640">
<img src="https://imgur.com/SFPdC7g.png" width="640">
<img src="https://imgur.com/CTFkYAj.png" width="640">
<img src="https://imgur.com/57dAAP8.png" width="640">
<img src="https://imgur.com/T5ayduK.png" width="640">
<img src="https://imgur.com/I3Gaze9.png" width="640">
<img src="https://imgur.com/qn9aThu.png" width="640">
<img src="https://imgur.com/eEfU2we.png" width="640">
<img src="https://imgur.com/7OSISYJ.png" width="640">

# Why Haxe?
I chose Haxe because its a good language that can target other languages, meaning any Haxe code can be converted and used in Python, C++, Java very easily so that nobody has to take effort in porting the code to different languages, atleast thats what my mindset was when I started it, but unfortunately because of the 3d engine I used, it only compiles to C and Javascript. You will have to isolate the engine specific features yourself if you want to use this for other programming languages.

# Build
The `master` branch is currently for Marble Blast Platinum. 
If you want to build Marble Blast Ultra, go to the [mbu-port](https://github.com/RandomityGuy/MBHaxe/tree/mbu-port) branch.    
If you want to build Marble Blast Gold, go to the [mbg](https://github.com/RandomityGuy/MBHaxe/tree/mbg) branch.  

Requires Haxe 4.3.0 or above
You require the following Haxe libraries: 
- heaps: The specific version located [here](https://github.com/RandomityGuy/heaps)
- hlsdl (Obtain the haxelib version of hlsdl, then patch it with these files [here](https://github.com/RandomityGuy/hashlink/tree/master/libs/sdl)) (Hashlink/C native target)
- stb_ogg_sound (JS/Browser target)
- zip 1.1.0 (JS/Browser target)

## Hashlink/Native
The version of hashlink to be compiled is located [here](https://github.com/RandomityGuy/hashlink).  
After all that has been setup, compile to hashlink by doing `haxe compile.hxml` and then running the game by `hl marblegame.hl`.  
To compile to C, do `haxe compile-c.hxml` and use the instructions in https://gist.github.com/Yanrishatum/d69ed72e368e35b18cbfca726d81279a

## Javascript/Browser
If the build dependencies are fullfilled, compile with `haxe compile-js.hxml` and run the game by running a web server in the same directory as the repo where index.html is located.

## MacOS
See [here](README-macOS.md)

## Android
The branches used for Android builds are `mbg-android`, `mbp-android-new` or `mbu-android`.  
Clone [this repository](https://github.com/RandomityGuy/MBHaxeAndroidLibs) containing the necessary libraries for the build and merge its src folder with that of Export/android/app/src folder.  
Android NDK version 18.1.5063045 and platform SDK version 31 is needed.  
Install zyheaps haxelib as well.  
Finally run `gradlew` in Export/android folder and run `gradlew assembleRelease`  
This will build the apk file at Export/android/app/build/outputs/apk/release/app-release-unsigned.apk which you can sign yourself and install on your device.  

# FAQ

## Help I am able to reproduce a crash!
If you are on browser, please send the browser console log to me
If you are on native, please run marbleblast-debug.bat and reproduce the crash, send the resulting stacktrace that occurs during the crash to me.

## Help it shows a black screen when playing a level!
Your PC does not support the game, please upgrade it, there is nothing I can do about it to fix it.

## How accurate are the marble physics?
Very accurate with up to 1% deviation from the original physics. The deviations are due to traplaunches being slightly different and occassional internal edge collisions, and the lower delta t values for physics simulations.

## How do I change my resolution?
In browser, you can just resize your window. You can use the browser zoom feature (ctrl + scroll) to change the UI size.  
In native version, you can just resize the window if windowed or use the resolution options in the menu or just directly modify settings.json  

## How do I change my FOV?
Edit settings.json for native version, edit the MBHaxeSettings key in LocalStorage in browser.  
In the platinum version, there is an FOV slider.

## How do I unlock/lock FPS?
You cannot unlock fps in the browser, it is forever set to vsync.
In the native version, edit settings.json or the options menu in the platinum.

## Hey can you please add this new feature?
If this new feature of yours already exists in MBG but not in this port, then I will try to add it, if I get time to do so, otherwise chances are, I won't add it since I have other things to do and would rather not waste my time on this any further. You are free to do pull requests if you have already implemented said feature.

# Notes
This project is tested with BrowserStack.
