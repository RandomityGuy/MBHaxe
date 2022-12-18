# Building on macOS

Required:
- CMake to build dependencies
- Hashlink (to build Universal: https://github.com/nullobsi/hashlink)
- SDL2
- libjpeg
- libjpegturbo
- libogg
- libvorbis
- libpng
- openal-soft
- zlib

## Building dependencies for Universal
I've found that using CMake makes building universal binaries on macOS a
lot easier.

Here's the process for dependencies that use CMake:
```sh
cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64" -DCMAKE_OSX_DEPLOYMENT_TARGET="10.15" -DBUILD_SHARED_LIBS=ON -DCMAKE_FIND_FRAMEWORK=LAST
cmake --build build --config Release -j8
sudo cmake --install build
```
This will build + install a CMake project as a Universal binary. It's
important that every dependency in the chain be universal for this to
work, otherwise you will get linking errors.

Some notes:
- When compiling Hashlink, you may need to disable `uv` and `ssl` as
  these are not needed by MBHaxe

Please see the other readme for Haxe libraries as you will need to use a
custom version of Heaps and HLSDL.

## Compiling MBHaxe
Use `haxe compile-c.hxml` to generate the `native` directory. If you're
going to build a .app bundle, use compile-macos.hxml instead.

cd into the native directory, then use the following command to build:
```sh
# Sometimes needed because of HLSDL.
sed -i -e 's/?sdl/sdl/g' sdl/Window.c hl/natives.h hl/functions.c sdl/Sdl.c

clang -mmacosx-version-min=10.15 -arch x86_64 -arch arm64 -o marblegame -I . -L /usr/local/lib/ -std=c11 marblegame.c /usr/local/lib/{ui.hdll, openal.hdll, fmt.hdll, sdl.hdll} -lsdl2 -lhl
```
This assumes you built all the libraries and installed them to
/usr/local/lib. 

## Packaging for macOS .app format
After compiling native/marblegame.c successfully, use the script
`./package-macos.sh` to create the skeleton app bundle under macos-dist.

Finally, you need to use `otool` and `install_name_tool` to redirect the
library paths to @rpath/lib.dylib.

marblegame should already have the rpath set. You just need to make sure
it's correct and copy the libs:
- fmt.hdll
- libSDL2-2.0.0.dylib
- libhl.dylib
- libogg.dylib
- libopenal.dylib
- libpng16.dylib
- libturbojpeg.dylib
- libvorbis.dylib
- libvorbisfile.dylib
- libz.dylib
- openal.dylib
- sdl.hdll
- ui.hdll

Ensure that they all depend on eachother with @rpath, as that will be
set to the correct directory when running marblegame. `otool -L` is
useful to check.

Sign the .app with `codesign` and it should be ready to go.

