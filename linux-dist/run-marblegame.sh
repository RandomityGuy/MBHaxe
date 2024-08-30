#!/usr/bin/env bash

cd "$(dirname "$0")"

# Add the current directory to the linker path so the .hdll files can be loaded
if [ "x$LD_LIBRARY_PATH" = "x" ]; then
	export LD_LIBRARY_PATH=.
else
	export LD_LIBRARY_PATH=".:$LD_LIBRARY_PATH"
fi

./marblegame $@
