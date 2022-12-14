# MBHaxe
A Haxe port of Marble Blast Gold and Platinum, name subject to change.
The marble physics code was taken from [OpenMBU](https://github.com/MBU-Team/OpenMBU) along with my own collision detection code, game logic was partially from scratch and taken with permission from [Marble Blast Web Port](https://github.com/Vanilagy/MarbleBlast).

# Play
## Web Browser
The browser port supports touch controls, meaning it can be played on mobile devices.
### Marble Blast Gold: [Play](https://mbhaxe.netlify.app/)
### Marble Blast Platinum: [Play](https://mbphaxe.netlify.app/)
## Windows
### Marble Blast Gold: [Download](https://github.com/RandomityGuy/MBHaxe/releases/tag/1.1.2)
### Marble Blast Platinum: [Download](https://github.com/RandomityGuy/MBHaxe/releases/tag/1.3.0)

# Why Haxe?
I chose Haxe because its a good language that can target other languages, meaning any Haxe code can be converted and used in Python, C++, Java very easily so that nobody has to take effort in porting the code to different languages, atleast thats what my mindset was when I started it, but unfortunately because of the 3d engine I used, it only compiles to C and Javascript. You will have to isolate the engine specific features yourself if you want to use this for other programming languages.

# Screenshots
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

# Build
The `master` branch is currently for Marble Blast Platinum. 
If you want to build Marble Blast Gold, look for version [1.1.2 tag](https://github.com/RandomityGuy/MBHaxe/commits/1.1.2)

Requires Haxe 4.2.2 or above
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
Edit settings.json for native version, edit the MBHaxeSettings key in LocalStorage in browser

## How do I unlock/lock FPS?
You cannot unlock fps in the browser, it is forever set to vsync.
In the native version, edit settings.json

## Hey can you please add this new feature?
If this new feature of yours already exists in MBG but not in this port, then I will try to add it, if I get time to do so, otherwise chances are, I won't add it since I have other things to do and would rather not waste my time on this any further. You are free to do pull requests if you have already implemented said feature.