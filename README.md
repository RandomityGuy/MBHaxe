# MBHaxe
A Haxe port of Marble Blast Gold, name subject to change.

# Build
Requires Haxe 4.2.2  
You require the following Haxe libraries: 
- heaps: 1.9.1 (not the git version)
- hlsdl (You will have to update it manually by replacing the files after doing the below steps)

You also have to compile your own version of Hashlink with https://github.com/HaxeFoundation/hashlink/pull/444 applied  
After all that has been setup, copy the data folder of MBG to the repo directory, compile to hashlink by doing `haxe compile.hxml` and then running the game by `hl marblegame.hl`

