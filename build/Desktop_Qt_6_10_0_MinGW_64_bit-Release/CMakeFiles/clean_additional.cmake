# Additional clean files
cmake_minimum_required(VERSION 3.16)

if("${CONFIG}" STREQUAL "" OR "${CONFIG}" STREQUAL "Release")
  file(REMOVE_RECURSE
  "CMakeFiles\\appiptv_player_autogen.dir\\AutogenUsed.txt"
  "CMakeFiles\\appiptv_player_autogen.dir\\ParseCache.txt"
  "appiptv_player_autogen"
  )
endif()
