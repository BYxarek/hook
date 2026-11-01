# Keep the upstream submodule reproducible; compile a patched copy until LSPlant caches backup IDs.
set(lsplant_source "${CMAKE_CURRENT_SOURCE_DIR}/lsplant/lsplant/src/main/jni/lsplant.cc")
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${lsplant_source}")
file(READ "${lsplant_source}" lsplant_code)

function(replace_lsplant_code before after)
    string(FIND "${lsplant_code}" "${before}" position)
    if(position EQUAL -1)
        message(FATAL_ERROR "LSPlant backup ID patch no longer matches upstream: ${before}")
    endif()
    string(REPLACE "${before}" "${after}" lsplant_code "${lsplant_code}")
    set(lsplant_code "${lsplant_code}" PARENT_SCOPE)
endfunction()

replace_lsplant_code("jmethodID method_get_name = nullptr;" [=[
// A backup's JNI ID must be retained from BuildDex, before DoHook changes its ArtMethod.
SharedHashMap<ArtMethod *, jmethodID> backup_method_ids;
jmethodID method_get_name = nullptr;]=])
replace_lsplant_code("    if (DoHook(target, hook, backup)) {" [=[
    if (DoHook(target, hook, backup)) {
        backup_method_ids.emplace(backup, backup_method);]=])
replace_lsplant_code([=[    // Encode before the backup is unregistered: with opaque JNI ids (java-debuggable runtime)
    // this call goes through JniIdManager::EncodeGenericId, which relies on IsBackup().
    auto *backup_method = env->FromReflectedMethod(reflected_backup);]=] [=[    jmethodID backup_method = nullptr;
    backup_method_ids.erase_if(backup, [&backup_method](const auto &it) {
        backup_method = it.second;
        return true;
    });]=])

string(FIND "${lsplant_code}" "FromReflectedMethod(reflected_backup)" forbidden_backup_id)
if(NOT forbidden_backup_id EQUAL -1)
    message(FATAL_ERROR "LSPlant must not obtain a JNI ID from the modified backup")
endif()
file(CONFIGURE OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/lsplant_patched.cc" CONTENT "${lsplant_code}" @ONLY)
get_target_property(lsplant_sources lsplant_static SOURCES)
list(REMOVE_ITEM lsplant_sources lsplant.cc)
set_property(TARGET lsplant_static PROPERTY SOURCES "${lsplant_sources};${CMAKE_CURRENT_BINARY_DIR}/lsplant_patched.cc")
