#!/bin/bash

haxe compile-linux.hxml
cd native
gcc -o marblegame -g -I . -L /usr/local/lib marblegame.c /usr/local/lib/{ui.hdll,openal.hdll,fmt.hdll,sdl.hdll,uv.hdll,ssl.hdll} -lSDL2 -lhl -lm
cp marblegame ..
