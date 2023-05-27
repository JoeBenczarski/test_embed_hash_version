set(BUILD_REV 0)

set(CURRENT_LIST_DIR ${CMAKE_CURRENT_LIST_DIR})
if(NOT DEFINED pre_configure_dir)
  set(pre_configure_dir ${CMAKE_CURRENT_LIST_DIR})
endif()

if(NOT DEFINED post_configure_dir)
  set(post_configure_dir ${CMAKE_BINARY_DIR}/generated)
endif()

set(pre_configure_file ${pre_configure_dir}/version.cpp.in)
set(post_configure_file ${post_configure_dir}/version.cpp)

function(check_version_write year month rev hash)
  file(WRITE ${CMAKE_BINARY_DIR}/version-state.txt
"${year}
${month}
${rev}
${hash}")
endfunction()

function(check_version_read year month rev hash)
  if(EXISTS ${CMAKE_BINARY_DIR}/version-state.txt)
    file(STRINGS ${CMAKE_BINARY_DIR}/version-state.txt CONTENT)
    list(GET CONTENT 0 var_year)
    list(GET CONTENT 1 var_month)
    list(GET CONTENT 2 var_rev)
    list(GET CONTENT 3 var_hash)

    set(${year}
        ${var_year}
        PARENT_SCOPE)
    set(${month}
        ${var_month}
        PARENT_SCOPE)
    set(${rev}
        ${var_rev}
        PARENT_SCOPE)
    set(${hash}
        ${var_hash}
        PARENT_SCOPE)
  endif()
endfunction()

function(check_version)
  # Get the latest abbreviated commit hash of the working branch
  execute_process(
    COMMAND git log -1 --format=%h
    WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
    OUTPUT_VARIABLE BUILD_HASH
    OUTPUT_STRIP_TRAILING_WHITESPACE)

  check_version_read(BUILD_YEAR_CACHE BUILD_MONTH_CACHE BUILD_REV_CACHE
                     BUILD_HASH_CACHE)
  if(NOT EXISTS ${post_configure_dir})
    file(MAKE_DIRECTORY ${post_configure_dir})
  endif()

  if(NOT EXISTS ${post_configure_dir}/version.h)
    file(COPY ${pre_configure_dir}/version.h DESTINATION ${post_configure_dir})
  endif()

  if(NOT DEFINED BUILD_YEAR_CACHE)
    set(BUILD_YEAR_CACHE "INVALID")
  endif()

  if(NOT DEFINED BUILD_MONTH_CACHE)
    set(BUILD_MONTH_CACHE "INVALID")
  endif()

  if(NOT DEFINED BUILD_REV_CACHE)
    set(BUILD_REV_CACHE "INVALID")
  endif()

  if(NOT DEFINED BUILD_HASH_CACHE)
    set(BUILD_HASH_CACHE "INVALID")
  endif()

  string(TIMESTAMP BUILD_YEAR "%Y")
  string(TIMESTAMP BUILD_MONTH "%m")

  # Only update the version.cpp if the hash has changed. This will prevent us
  # from rebuilding the project more than we need to.
  if(NOT ${BUILD_YEAR} STREQUAL ${BUILD_YEAR_CACHE}
     OR NOT ${BUILD_MONTH} STREQUAL ${BUILD_MONTH_CACHE}
     OR NOT ${BUILD_REV} STREQUAL ${BUILD_REV_CACHE}
     OR NOT ${BUILD_HASH} STREQUAL ${BUILD_HASH_CACHE}
     OR NOT EXISTS ${post_configure_file})
    # Set che BUILD_HASH_CACHE variable the next build won't have to regenerate
    # the source file.
    check_version_write(${BUILD_YEAR} ${BUILD_MONTH} ${BUILD_REV} ${BUILD_HASH})
    configure_file(${pre_configure_file} ${post_configure_file} @ONLY)
  endif()

endfunction()

function(CheckVersion)

  add_custom_target(
    AlwaysCheckVersion
    COMMAND
      ${CMAKE_COMMAND} -DRUN_CHECK_VERSION=1
      -Dpre_configure_dir=${pre_configure_dir}
      -Dpost_configure_file=${post_configure_dir}
      -DBUILD_YEAR_CACHE=${BUILD_YEAR_CACHE}
      -DBUILD_MONTH_CACHE=${BUILD_MONTH_CACHE}
      -DBUILD_REV_CACHE=${BUILD_REV_CACHE}
      -DBUILD_HASH_CACHE=${BUILD_HASH_CACHE} -P ${CURRENT_LIST_DIR}/CheckVersion.cmake
    BYPRODUCTS ${post_configure_file}
    COMMENT "Building target version")

  add_library(version ${post_configure_file})
  target_include_directories(version PUBLIC ${CMAKE_BINARY_DIR}/generated)
  add_dependencies(version AlwaysCheckVersion)

  check_version()
endfunction()

# This is used to run this function from an external cmake process.
if(RUN_CHECK_VERSION)
  check_version()
endif()
