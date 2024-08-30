#!/bin/bash

haxe compile-linux.hxml
cd native
gcc -o marblegame -O2 -I . -L /usr/local/lib marblegame.c /usr/local/lib/{ui.hdll,openal.hdll,fmt.hdll,sdl.hdll,uv.hdll,ssl.hdll,datachannel.hdll} -lSDL2 -lhl -lm -luv
strip marblegame
cp marblegame ..
