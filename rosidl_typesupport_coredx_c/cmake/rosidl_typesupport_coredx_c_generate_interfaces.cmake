# Copyright 2016 Open Source Robotics Foundation, Inc.
# Modifications copyright (C) 2017 Twin Oaks Computing, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set(_ros_idl_files "")
foreach(_idl_file ${rosidl_generate_interfaces_IDL_FILES})
  get_filename_component(_extension "${_idl_file}" EXT)
  # Skip .srv files
  if(_extension STREQUAL ".msg")
    list(APPEND _ros_idl_files "${_idl_file}")
  endif()
endforeach()

set(_dds_idl_files "")
set(_dds_idl_base_path "${CMAKE_CURRENT_BINARY_DIR}/rosidl_generator_dds_idl")
foreach(_idl_file ${rosidl_generate_interfaces_IDL_FILES})
  get_filename_component(_extension "${_idl_file}" EXT)
  if(_extension STREQUAL ".msg")
    get_filename_component(_parent_folder "${_idl_file}" DIRECTORY)
    get_filename_component(_parent_folder "${_parent_folder}" NAME)
    get_filename_component(_name "${_idl_file}" NAME_WE)
    list(APPEND _dds_idl_files
      "${_dds_idl_base_path}/${PROJECT_NAME}/${_parent_folder}/dds_coredx/${_name}_.idl")
  endif()
endforeach()

set(_output_path "${CMAKE_CURRENT_BINARY_DIR}/rosidl_typesupport_coredx_c/${PROJECT_NAME}")
set(_dds_output_path "${CMAKE_CURRENT_BINARY_DIR}/rosidl_typesupport_coredx_cpp/${PROJECT_NAME}")
set(_generated_files "")
set(_generated_external_files "")
foreach(_idl_file ${rosidl_generate_interfaces_IDL_FILES})
  get_filename_component(_parent_folder "${_idl_file}" DIRECTORY)
  get_filename_component(_parent_folder "${_parent_folder}" NAME)
  get_filename_component(_extension "${_idl_file}" EXT)
  get_filename_component(_msg_name "${_idl_file}" NAME_WE)
  string_camel_case_to_lower_case_underscore("${_msg_name}" _header_name)
  if(_extension STREQUAL ".msg" AND _msg_name MATCHES "Response$|Request$")
    # Don't do anything
  elseif(_extension STREQUAL ".msg")
    set(_allowed_parent_folders "msg" "srv" "action")
    if(NOT _parent_folder IN_LIST _allowed_parent_folders)
      message(FATAL_ERROR "Interface file with unknown parent folder: ${_idl_file}")
    endif()
    list(APPEND _generated_external_files "${_dds_output_path}/${_parent_folder}/dds_coredx/${_msg_name}_.hh")
    list(APPEND _generated_external_files "${_dds_output_path}/${_parent_folder}/dds_coredx/${_msg_name}_.cc")
    list(APPEND _generated_external_files "${_dds_output_path}/${_parent_folder}/dds_coredx/${_msg_name}_DataReader.hh")
    list(APPEND _generated_external_files "${_dds_output_path}/${_parent_folder}/dds_coredx/${_msg_name}_DataReader.cc")
    list(APPEND _generated_external_files "${_dds_output_path}/${_parent_folder}/dds_coredx/${_msg_name}_DataWriter.hh")
    list(APPEND _generated_external_files "${_dds_output_path}/${_parent_folder}/dds_coredx/${_msg_name}_DataWriter.cc")
    list(APPEND _generated_external_files "${_dds_output_path}/${_parent_folder}/dds_coredx/${_msg_name}_TypeSupport.hh")
    list(APPEND _generated_external_files "${_dds_output_path}/${_parent_folder}/dds_coredx/${_msg_name}_TypeSupport.cc")
    list(APPEND _generated_files "${_output_path}/${_parent_folder}/${_header_name}__rosidl_typesupport_coredx_c.h")
    list(APPEND _generated_files "${_output_path}/${_parent_folder}/dds_coredx_c/${_header_name}__type_support_c.cpp")
  elseif(_extension STREQUAL ".srv")
    set(_allowed_parent_folders "srv" "action")
    if(NOT _parent_folder IN_LIST _allowed_parent_folders)
      message(FATAL_ERROR "Interface file with unknown parent folder: ${_idl_file}")
    endif()
    list(APPEND _generated_files "${_output_path}/${_parent_folder}/${_header_name}__rosidl_typesupport_coredx_c.h")
    list(APPEND _generated_files "${_output_path}/${_parent_folder}/dds_coredx_c/${_header_name}__type_support_c.cpp")
    list(APPEND _generated_files "${_output_path}/${_parent_folder}/dds_coredx_c/${_header_name}__request__type_support_c.cpp")
    list(APPEND _generated_files "${_output_path}/${_parent_folder}/dds_coredx_c/${_header_name}__response__type_support_c.cpp")
  else()
    message(FATAL_ERROR "Interface file with unknown extension: ${_idl_file}")
  endif()

endforeach()

# If not on Windows, disable some warnings with TOC CoreDX DDS's generated code
if(NOT WIN32)
  set(_coredx_compile_flags)
  if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    set(_coredx_compile_flags
    )
  elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    set(_coredx_compile_flags
      )
  endif()
  if(NOT _coredx_compile_flags STREQUAL "")
    string(REPLACE ";" " " _coredx_compile_flags "${_coredx_compile_flags}")
    foreach(_gen_file ${_generated_external_files})
      set_source_files_properties("${_gen_file}"
        PROPERTIES COMPILE_FLAGS "${_coredx_compile_flags}")
    endforeach()
  endif()
endif()

set(_dependency_files "")
set(_dependencies "")
foreach(_pkg_name ${rosidl_generate_interfaces_DEPENDENCY_PACKAGE_NAMES})
  foreach(_idl_file ${${_pkg_name}_INTERFACE_FILES})
    get_filename_component(_extension "${_idl_file}" EXT)
    if(_extension STREQUAL ".msg")
      get_filename_component(_parent_folder "${_idl_file}" DIRECTORY)
      get_filename_component(_parent_folder "${_parent_folder}" NAME)
      get_filename_component(_name "${_idl_file}" NAME_WE)
      set(_abs_idl_file "${${_pkg_name}_DIR}/../${_parent_folder}/dds_coredx/${_name}_.idl")
      normalize_path(_abs_idl_file "${_abs_idl_file}")
      list(APPEND _dependency_files "${_abs_idl_file}")
      set(_abs_idl_file "${${_pkg_name}_DIR}/../${_idl_file}")
      normalize_path(_abs_idl_file "${_abs_idl_file}")
      list(APPEND _dependencies "${_pkg_name}:${_abs_idl_file}")
    endif()
  endforeach()
endforeach()

set(target_dependencies
  "${rosidl_typesupport_coredx_c_BIN}"
  ${rosidl_typesupport_coredx_c_GENERATOR_FILES}
  "${rosidl_typesupport_coredx_c_TEMPLATE_DIR}/msg__type_support_c.cpp.em"
  "${rosidl_typesupport_coredx_c_TEMPLATE_DIR}/srv__type_support_c.cpp.em"
  ${_dependency_files})
foreach(dep ${target_dependencies})
  if(NOT EXISTS "${dep}")
    message(FATAL_ERROR "Target dependency '${dep}' does not exist")
  endif()
endforeach()

set(generator_arguments_file "${CMAKE_CURRENT_BINARY_DIR}/rosidl_typesupport_coredx_c__arguments.json")
rosidl_write_generator_arguments(
  "${generator_arguments_file}"
  PACKAGE_NAME "${PROJECT_NAME}"
  ROS_INTERFACE_FILES "${rosidl_generate_interfaces_IDL_FILES}"
  ROS_INTERFACE_DEPENDENCIES "${_dependencies}"
  OUTPUT_DIR "${_output_path}"
  TEMPLATE_DIR "${rosidl_typesupport_coredx_c_TEMPLATE_DIR}"
  TARGET_DEPENDENCIES ${target_dependencies}
  ADDITIONAL_FILES ${_dds_idl_files}
)

add_custom_command(
  OUTPUT ${_generated_files} 
  COMMAND ${PYTHON_EXECUTABLE} ${rosidl_typesupport_coredx_c_BIN}
  --generator-arguments-file "${generator_arguments_file}"
  DEPENDS
    ${target_dependencies}
    ${_generated_external_files}
    ${_dds_idl_files}
  COMMENT "Generating C type support for TOC CoreDX DDS"
  VERBATIM
)

# generate header to switch between export and import for a specific package
set(_visibility_control_file
"${_output_path}/msg/rosidl_typesupport_coredx_c__visibility_control.h")
string(TOUPPER "${PROJECT_NAME}" PROJECT_NAME_UPPER)
configure_file(
  "${rosidl_typesupport_coredx_c_TEMPLATE_DIR}/rosidl_typesupport_coredx_c__visibility_control.h.in"
  "${_visibility_control_file}"
  @ONLY
)

set(_target_suffix "__rosidl_typesupport_coredx_c")

link_directories(${CoreDX_LIBRARY_DIRS})
add_library(${rosidl_generate_interfaces_TARGET}${_target_suffix} SHARED
  ${_generated_files} ${_generated_external_files} )
if(rosidl_generate_interfaces_LIBRARY_NAME)
  set_target_properties(${rosidl_generate_interfaces_TARGET}${_target_suffix}
    PROPERTIES OUTPUT_NAME "${rosidl_generate_interfaces_LIBRARY_NAME}${_target_suffix}")
endif()

if(CoreDX_GLIBCXX_USE_CXX11_ABI_ZERO)
  target_compile_definitions(${rosidl_generate_interfaces_TARGET}${_target_suffix}
    PRIVATE CoreDX_GLIBCXX_USE_CXX11_ABI_ZERO)
endif()

ament_target_dependencies(${rosidl_generate_interfaces_TARGET}${_target_suffix}
  "rmw"
  "rosidl_typesupport_coredx_cpp"
  "rosidl_generator_c"
  "rosidl_typesupport_interface")
if(WIN32)
  target_compile_definitions(${rosidl_generate_interfaces_TARGET}${_target_suffix}
    PRIVATE "ROSIDL_TYPESUPPORT_COREDX_C_BUILDING_DLL_${PROJECT_NAME}")
  target_compile_definitions(${rosidl_generate_interfaces_TARGET}${_target_suffix}
    PRIVATE "COREDX_DLL_TS")
  target_compile_definitions(${rosidl_generate_interfaces_TARGET}${_target_suffix}
    PRIVATE "COREDX_DLL_TS_EXPORTS")
endif()

if(NOT WIN32)
  set(_target_compile_flags "-Wall -Wextra -Wpedantic")
else()
  set(_target_compile_flags
    "/W4"  # Enable level 3 warnings
    "/wd4100"  # Ignore unreferenced formal parameter warnings
    "/wd4127"  # Ignore conditional expression is constant warnings
    "/wd4275"  # Ignore "an exported class derived from a non-exported class" warnings
    "/wd4305"  # Ignore "initializing: truncation from..." warnings
    "/wd4458"  # Ignore class hides member variable warnings
    "/wd4701"  # Ignore unused variable warnings
  )
endif()
string(REPLACE ";" " " _target_compile_flags "${_target_compile_flags}")
set_target_properties(${rosidl_generate_interfaces_TARGET}${_target_suffix}
  PROPERTIES COMPILE_FLAGS "${_target_compile_flags}")
target_include_directories(${rosidl_generate_interfaces_TARGET}${_target_suffix}
  PUBLIC
  ${CMAKE_CURRENT_BINARY_DIR}/rosidl_generator_c
  ${CMAKE_CURRENT_BINARY_DIR}/rosidl_generator_cpp
  ${CMAKE_CURRENT_BINARY_DIR}/rosidl_typesupport_coredx_c
  ${CMAKE_CURRENT_BINARY_DIR}/rosidl_typesupport_coredx_cpp
)
ament_target_dependencies(${rosidl_generate_interfaces_TARGET}${_target_suffix}
  "CoreDX"
  "rosidl_typesupport_coredx_c"
  "${PROJECT_NAME}__rosidl_typesupport_coredx_cpp")
foreach(_pkg_name ${rosidl_generate_interfaces_DEPENDENCY_PACKAGE_NAMES})
  set(_msg_include_dir "${${_pkg_name}_DIR}/../../../include/${_pkg_name}/msg/dds_coredx_c")
  set(_srv_include_dir "${${_pkg_name}_DIR}/../../../include/${_pkg_name}/srv/dds_coredx_c")
  set(_action_include_dir "${${_pkg_name}_DIR}/../../../include/${_pkg_name}/action/dds_coredx_c")
  normalize_path(_msg_include_dir "${_msg_include_dir}")
  normalize_path(_srv_include_dir "${_srv_include_dir}")
  normalize_path(_action_include_dir "${_action_include_dir}")
  target_include_directories(${rosidl_generate_interfaces_TARGET}${_target_suffix}
    PUBLIC
    "${_msg_include_dir}"
    "${_srv_include_dir}"
    "${_action_include_dir}"
  )
  ament_target_dependencies(${rosidl_generate_interfaces_TARGET}${_target_suffix}
    ${_pkg_name})
  target_link_libraries(${rosidl_generate_interfaces_TARGET}${_target_suffix}
    ${${_pkg_name}_LIBRARIES${_target_suffix}})
endforeach()
target_link_libraries(${rosidl_generate_interfaces_TARGET}${_target_suffix}
  ${rosidl_generate_interfaces_TARGET}__rosidl_generator_c
  ${rosidl_generate_interfaces_TARGET}__rosidl_typesupport_coredx_cpp)

add_dependencies(
  ${rosidl_generate_interfaces_TARGET}
  ${rosidl_generate_interfaces_TARGET}${_target_suffix}
)
add_dependencies(
  ${rosidl_generate_interfaces_TARGET}${_target_suffix}
  ${rosidl_generate_interfaces_TARGET}__rosidl_typesupport_coredx_cpp
)
add_dependencies(
  ${rosidl_generate_interfaces_TARGET}${_target_suffix}
  ${rosidl_generate_interfaces_TARGET}__cpp
)
add_dependencies(
  ${rosidl_generate_interfaces_TARGET}${_target_suffix}
  ${rosidl_generate_interfaces_TARGET}__dds_coredx_idl
)

if(NOT rosidl_generate_interfaces_SKIP_INSTALL)
  install(
    DIRECTORY "${_output_path}/"
    DESTINATION "include/${PROJECT_NAME}"
    PATTERN "*.cpp" EXCLUDE
  )

  if(NOT _generated_files STREQUAL "" )
    ament_export_include_directories(include)
  endif()

  install(
    TARGETS ${rosidl_generate_interfaces_TARGET}${_target_suffix}
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
  )

  rosidl_export_typesupport_libraries(${_target_suffix} ${rosidl_generate_interfaces_TARGET}${_target_suffix})
endif()

if(BUILD_TESTING AND rosidl_generate_interfaces_ADD_LINTER_TESTS)
  if(NOT _generated_files STREQUAL "")
    find_package(ament_cmake_cppcheck REQUIRED)
    ament_cppcheck(
      TESTNAME "cppcheck_rosidl_typesupport_coredx_c"
      ${_generated_files})

    find_package(ament_cmake_cpplint REQUIRED)
    get_filename_component(_cpplint_root "${_output_path}" DIRECTORY)
    ament_cpplint(
      TESTNAME "cpplint_rosidl_typesupport_coredx_c"
      # the generated code might contain longer lines for templated types
      MAX_LINE_LENGTH 999
      ROOT "${_cpplint_root}"
      ${_generated_files})

    find_package(ament_cmake_uncrustify REQUIRED)
    ament_uncrustify(
      TESTNAME "uncrustify_rosidl_typesupport_coredx_c"
      # the generated code might contain longer lines for templated types
      MAX_LINE_LENGTH 0
      ${_generated_files})
  endif()
endif()
