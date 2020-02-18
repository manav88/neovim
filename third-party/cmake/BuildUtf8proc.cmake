include(CMakeParseArguments)

# BuildUtf8proc(CONFIGURE_COMMAND ... BUILD_COMMAND ... INSTALL_COMMAND ...)
# Reusable function to build utf8proc, wraps ExternalProject_Add.
# Failing to pass a command argument will result in no command being run
function(BuildUtf8proc)
  cmake_parse_arguments(_utf8proc
    ""
    ""
    "CONFIGURE_COMMAND;BUILD_COMMAND;INSTALL_COMMAND"
    ${ARGN})

  if(NOT _utf8proc_CONFIGURE_COMMAND AND NOT _utf8proc_BUILD_COMMAND
       AND NOT _utf8proc_INSTALL_COMMAND)
    message(FATAL_ERROR "Must pass at least one of CONFIGURE_COMMAND, BUILD_COMMAND, INSTALL_COMMAND")
  endif()

  ExternalProject_Add(utf8proc
    PREFIX ${DEPS_BUILD_DIR}
    URL ${UTF8PROC_URL}
    DOWNLOAD_DIR ${DEPS_DOWNLOAD_DIR}/utf8proc
    DOWNLOAD_COMMAND ${CMAKE_COMMAND}
      -DPREFIX=${DEPS_BUILD_DIR}
      -DDOWNLOAD_DIR=${DEPS_DOWNLOAD_DIR}/utf8proc
      -DURL=${UTF8PROC_URL}
      -DEXPECTED_SHA256=${UTF8PROC_SHA256}
      -DTARGET=utf8proc
      -DUSE_EXISTING_SRC_DIR=${USE_EXISTING_SRC_DIR}
      -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/DownloadAndExtractFile.cmake
    CONFIGURE_COMMAND "${_utf8proc_CONFIGURE_COMMAND}"
    BUILD_COMMAND "${_utf8proc_BUILD_COMMAND}"
    INSTALL_COMMAND "${_utf8proc_INSTALL_COMMAND}")
endfunction()

set(UTF8PROC_CONFIGURE_COMMAND ${CMAKE_COMMAND} ${DEPS_BUILD_DIR}/src/utf8proc
  -DCMAKE_INSTALL_PREFIX=${DEPS_INSTALL_DIR}
  -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
  -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
  "-DCMAKE_C_FLAGS:STRING=${CMAKE_C_COMPILER_ARG1} -fPIC"
  -DCMAKE_GENERATOR=${CMAKE_GENERATOR})

set(UTF8PROC_BUILD_COMMAND ${CMAKE_COMMAND} --build . --config ${CMAKE_BUILD_TYPE})
set(UTF8PROC_INSTALL_COMMAND ${CMAKE_COMMAND} --build . --target install --config ${CMAKE_BUILD_TYPE})

if(MINGW AND CMAKE_CROSSCOMPILING)
  get_filename_component(TOOLCHAIN ${CMAKE_TOOLCHAIN_FILE} REALPATH)
  set(UTF8PROC_CONFIGURE_COMMAND ${CMAKE_COMMAND} ${DEPS_BUILD_DIR}/src/utf8proc
    -DCMAKE_INSTALL_PREFIX=${DEPS_INSTALL_DIR}
    # Pass toolchain
    -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN}
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    # Hack to avoid -rdynamic in Mingw
    -DCMAKE_SHARED_LIBRARY_LINK_C_FLAGS="")
elseif(MSVC)
  # Same as Unix without fPIC
  set(UTF8PROC_CONFIGURE_COMMAND ${CMAKE_COMMAND} ${DEPS_BUILD_DIR}/src/utf8proc
    -DCMAKE_INSTALL_PREFIX=${DEPS_INSTALL_DIR}
    -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
    "-DCMAKE_C_FLAGS:STRING=${CMAKE_C_COMPILER_ARG1}"
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    # Make sure we use the same generator, otherwise we may
    # accidentally end up using different MSVC runtimes
    -DCMAKE_GENERATOR=${CMAKE_GENERATOR})
endif()

BuildUtf8proc(CONFIGURE_COMMAND ${UTF8PROC_CONFIGURE_COMMAND}
  BUILD_COMMAND ${UTF8PROC_BUILD_COMMAND}
  INSTALL_COMMAND ${UTF8PROC_INSTALL_COMMAND})