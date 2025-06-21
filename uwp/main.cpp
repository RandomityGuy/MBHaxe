#include <Windows.h>
#define SDL_MAIN_HANDLED = 1
#include "SDL.h"

typedef wchar_t pchar;
extern "C" int wmain(int, pchar**);

int bootstrap(int, char**)
{
	SDL_Init(SDL_INIT_VIDEO);
	// That's it, run the main process
	return wmain(0, 0);
}

int CALLBACK WinMain(HINSTANCE h, HINSTANCE, LPSTR argv, int argc)
{
	return SDL_WinRTRunApp(bootstrap, NULL);
}
