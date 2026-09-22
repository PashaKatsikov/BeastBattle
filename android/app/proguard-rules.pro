-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

-keep class com.appsflyer.** { *; }
-dontwarn com.appsflyer.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

-keep class com.google.firebase.** { *; }
-keep class com.google.android.datatransport.** { *; }
-dontwarn com.google.firebase.**

-keep class com.beastbattle.beast_battle.MainActivity { *; }
-keepnames class kotlinx.** { *; }
-dontwarn kotlinx.coroutines.**
-dontwarn java.time.**
-dontwarn sun.misc.Unsafe
