cmake_minimum_required(VERSION 3.14)
include(FetchContent)

# Setup UWP platform
set(CMAKE_SYSTEM_NAME WindowsStore)
set(CMAKE_SYSTEM_VERSION 10.0.19041.0)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Define project
project(mbhaxe-uwp LANGUAGES CXX)
set_directory_properties(PROPERTIES VS_STARTUP_PROJECT ${PROJECT_NAME})

# Fetch shared UWP deps
FetchContent_Declare(UwpLibs
    GIT_REPOSITORY https://github.com/worleydl/uwp-dep.git
    GIT_TAG fccbcd95794f57c949caf94c6a7160f7f8d2b7e0
)
FetchContent_MakeAvailable(UwpLibs)


# Config for haxe dependency paths
set(DATACHANNEL_DIR CACHE PATH "")
set(HASHLINK_DIR CACHE PATH "")
set(MBHAXE_DIR CACHE PATH "")

add_executable(${PROJECT_NAME} WIN32
    main.cpp
)

set(BinDeps
	${DATACHANNEL_DIR}/datachannel.hdll
	${HASHLINK_DIR}/fmt.hdll
	${HASHLINK_DIR}/libhl.dll
	${HASHLINK_DIR}/openal.hdll
	${HASHLINK_DIR}/sdl.hdll
	${HASHLINK_DIR}/ssl.hdll
	${HASHLINK_DIR}/ui.hdll
	${HASHLINK_DIR}/uv.hdll

	${CMAKE_BINARY_DIR}/_deps/uwplibs-src/x64/bin/dxil.dll
	${CMAKE_BINARY_DIR}/_deps/uwplibs-src/x64/bin/libgallium_wgl.dll
	${CMAKE_BINARY_DIR}/_deps/uwplibs-src/x64/bin/OpenAL32.dll
	${CMAKE_BINARY_DIR}/_deps/uwplibs-src/x64/bin/opengl32.dll
	${CMAKE_BINARY_DIR}/_deps/uwplibs-src/x64/bin/SDL2.dll
	${CMAKE_BINARY_DIR}/_deps/uwplibs-src/x64/bin/z-1.dll

	cacert.pem
	Package.appxmanifest
)

set(BinLibs
	${DATACHANNEL_DIR}/datachannel.lib
	${HASHLINK_DIR}/fmt.lib
	${HASHLINK_DIR}/libhl.lib
	${HASHLINK_DIR}/openal.lib
	${HASHLINK_DIR}/sdl.lib
	${HASHLINK_DIR}/ssl.lib
	${HASHLINK_DIR}/ui.lib
	${HASHLINK_DIR}/uv.lib
	${MBHAXE_DIR}/marblegame.lib
)
source_group("BinDep" FILES ${BinDeps})

set_source_files_properties(${BinDeps} PROPERTIES
	VS_COPY_TO_OUT_DIR Always
	VS_DEPLOYMENT_CONTENT TRUE
	VS_DEPLOYMENT_LOCATION "."
)

# Setup data deployment
file(GLOB_RECURSE DATA_FILES
	RELATIVE ${CMAKE_SOURCE_DIR}/..
	${CMAKE_SOURCE_DIR}/../data/*
)

foreach(ASSET ${DATA_FILES})
	set(FULL_PATH "${CMAKE_SOURCE_DIR}/../${ASSET}")

	get_filename_component(DEST_DIR ${ASSET} DIRECTORY)

	set_source_files_properties("${FULL_PATH}" PROPERTIES
		VS_COPY_TO_OUT_DIR Always
		VS_DEPLOYMENT_CONTENT TRUE
		VS_DEPLOYMENT_LOCATION "${DEST_DIR}" # preserves folder structure
	)

	target_sources(${PROJECT_NAME} PRIVATE "${FULL_PATH}")
	source_group("BinData" FILES "${FULL_PATH}")
endforeach()

target_sources(${PROJECT_NAME} PRIVATE
	cacert.pem
	Package.appxmanifest
	${BinDeps}
)

target_link_libraries(${PROJECT_NAME} PRIVATE ${BinLibs} SDL2 WindowsApp.lib OneCore.lib)
set_target_properties(${PROJECT_NAME} PROPERTIES VS_WINDOWS_TARGET_PLATFORM_MIN_VERSION 10.0.19041.0)
