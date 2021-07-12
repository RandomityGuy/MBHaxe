# MBHaxe
A Haxe port of Marble Blast Gold, name subject to change.
Its currently a WIP at the time of writing. The marble physics code was taken from [OpenMBU](https://github.com/MBU-Team/OpenMBU) along with my own collision detection code, game logic was partially from scratch and taken with permission from [Marble Blast Web Port](https://github.com/Vanilagy/MarbleBlast).
The browser version of this port is hosted [here](https://mbhaxe.netlify.app/)

# Build
Requires Haxe 4.2.2  
You require the following Haxe libraries: 
- heaps: 1.9.1 (not the git version) with https://github.com/HeapsIO/heaps/pull/573 applied
- hlsdl (You will have to update it manually by replacing the files after doing the below steps) (Hashlink/C native target)
- stb_ogg_sound (JS/Browser target)

## Hashlink/Native
You have to compile your own version of Hashlink with https://github.com/HaxeFoundation/hashlink/pull/444 applied  
After all that has been setup, compile to hashlink by doing `haxe compile.hxml` and then running the game by `hl marblegame.hl`
To compile to C, use the instructions in https://gist.github.com/Yanrishatum/d69ed72e368e35b18cbfca726d81279a

## Javascript/Browser
If the build dependencies are fullfilled, compile with `haxe compile-js.hxml` and run the game by running a web server in the same directory as the repo where index.html is located.