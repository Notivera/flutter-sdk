# Consumer rules for notivera_flutter (applied when the host app enables minify/R8).
# Prefer also setting android.enableR8.fullMode=false in the host gradle.properties
# — R8 full mode can break Notivera Koin DI (e.g. NoBeanDefFoundException: SDKViewModel).

-keep class com.notivera.** { *; }
-keepclassmembers class com.notivera.** { *; }
-keep class com.notivera.notivera_flutter.** { *; }
-keep class org.koin.** { *; }
-dontwarn org.koin.**
