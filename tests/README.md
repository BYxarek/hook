# Standalone Android hook regression

`PluginNativeProbe.java` runs in `app_process` without creating an APK. It
checks 100 repeated hooks, modified arguments/results, restored original calls,
HashMap allocations and GC. Use the classes.jar and native libraries from the
same newly built AAR, not libraries from an installed client.

Example on a Unix host with Android SDK tools on PATH, from the repository root:

```sh
./gradlew :core:assembleRelease
mkdir -p build/native-probe/classes build/native-probe/dex build/native-probe/lib
unzip -p core/build/outputs/aar/core-release.aar classes.jar > build/native-probe/classes.jar
unzip -jo core/build/outputs/aar/core-release.aar 'jni/x86_64/*.so' -d build/native-probe/lib
javac --release 11 -cp build/native-probe/classes.jar -d build/native-probe/classes tests/PluginNativeProbe.java
d8 --min-api 21 --lib "$ANDROID_HOME/platforms/android-36/android.jar" --output build/native-probe/dex build/native-probe/classes.jar build/native-probe/classes/*.class
adb -s emulator-5554 shell mkdir -p /data/local/tmp/aliuhook-dobby-latest
adb -s emulator-5554 push build/native-probe/dex/classes.dex build/native-probe/lib/libaliuhook.so build/native-probe/lib/libc++_shared.so /data/local/tmp/aliuhook-dobby-latest/
adb -s emulator-5554 shell chmod 444 /data/local/tmp/aliuhook-dobby-latest/classes.dex
adb -s emulator-5554 shell 'CLASSPATH=/data/local/tmp/aliuhook-dobby-latest/classes.dex LD_LIBRARY_PATH=/data/local/tmp/aliuhook-dobby-latest timeout 120 app_process -Djava.library.path=/data/local/tmp/aliuhook-dobby-latest /system/bin PluginNativeProbe 100'
```

On 2026-11-01 the equivalent commands passed on x86_64 API 36 (4 KiB pages),
API 35 and 37 (16 KiB pages). Logs are in `build/dobby-latest-probe/`.
The release AAR contains four ABIs, no separate libdobby.so, and 16 KiB-aligned
ELF64 LOAD segments. The Dobby submodule's allocation regression also passed
on these three emulators, linked against the newly built static archive.

The local Gradle 8.14.3 wrapper download was unavailable, so this check used
installed Gradle 8.13 (compatible with AGP 8.11), JDK 21, NDK 30.0.16248370,
and CMake 4.1.2. ARM runtime and the full BYgram application were not tested.
