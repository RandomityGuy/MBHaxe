# MBHaxe
A Haxe port of Marble Blast Gold, name subject to change.
The marble physics code was taken from [OpenMBU](https://github.com/MBU-Team/OpenMBU) along with my own collision detection code, game logic was partially from scratch and taken with permission from [Marble Blast Web Port](https://github.com/Vanilagy/MarbleBlast).
The browser version of this port is hosted [here](https://mbhaxe.netlify.app/)

# Why Haxe?
I chose Haxe because its a good language that can target other languages, meaning any Haxe code can be converted and used in Python, C++, Java very easily so that nobody has to take effort in porting the code to different languages, atleast thats what my mindset was when I started it, but unfortunately because of the 3d engine I used, it only compiles to C and Javascript. You will have to isolate the engine specific features yourself if you want to use this for other programming languages.

# Build
Requires Haxe 4.2.2 or above
You require the following Haxe libraries: 
- heaps: 1.9.1 (not the git version) with https://github.com/HeapsIO/heaps/pull/573 applied
- hlsdl (You will have to update it manually by replacing the files after doing the below steps) (Hashlink/C native target)
- stb_ogg_sound (JS/Browser target)

## Hashlink/Native
You have to compile your own version of Hashlink with https://github.com/HaxeFoundation/hashlink/pull/444 applied  
After all that has been setup, compile to hashlink by doing `haxe compile.hxml` and then running the game by `hl marblegame.hl`
To compile to C, do `haxe compile-c.hxml` and use the instructions in https://gist.github.com/Yanrishatum/d69ed72e368e35b18cbfca726d81279a

## Javascript/Browser
If the build dependencies are fullfilled, compile with `haxe compile-js.hxml` and run the game by running a web server in the same directory as the repo where index.html is located.