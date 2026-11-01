# Changelog

## 2026-11-01

- Android: replace Maven Dobby 1.2 with a pinned source submodule based on
  latest LSPosed/Dobby `c1da031`, retaining the ART memory-mapping fix.
- Adapt the native inline hook callback to Dobby's function-pointer API;
  build Dobby statically into libaliuhook.so for the existing Android ABIs.
- Bump the library version to `1.1.4-api37.2`; build workflow produces the AAR
  without automatically creating example or instrumentation APKs.
- LSPlant remains pinned to `06bd341`; no application UI changes.
- Release AAR build passed for all four ABIs; ELF64 LOAD segments support
  16 KiB alignment. Standalone x86_64 API 35/36/37 checks passed 100 hook/unhook
  cycles each, callback results, HashMap stress and GC. ARM runtime and full
  BYgram integration were not exercised in this update.
