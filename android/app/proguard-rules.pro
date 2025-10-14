# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Critical attributes for reflection and annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Flutter embedding
-keep class io.flutter.embedding.** { *; }

# audio_service plugin (CRITICAL - prevent R8 from stripping these classes)
-keep class com.ryanheise.audioservice.** { *; }
-keepclassmembers class com.ryanheise.audioservice.** { *; }
-dontwarn com.ryanheise.audioservice.**

# Keep the AudioServiceActivity specifically
-keep public class * extends com.ryanheise.audioservice.AudioServiceActivity

# MediaSession and MediaBrowser (required for notifications and lock screen)
-keep class android.support.v4.media.** { *; }
-keep interface android.support.v4.media.** { *; }
-keep class androidx.media.** { *; }
-keep interface androidx.media.** { *; }
-keepclassmembers class androidx.media.** { *; }
-dontwarn android.support.v4.media.**
-dontwarn androidx.media.**

# MediaSession compatibility
-keep class androidx.media.session.** { *; }
-keep class android.support.v4.media.session.** { *; }

# Keep all Service classes (critical for background playback)
-keep public class * extends android.app.Service
-keep public class * extends androidx.media.MediaBrowserServiceCompat

# Keep BroadcastReceiver for media buttons
-keep public class * extends android.content.BroadcastReceiver

# Keep MainActivity (extends AudioServiceActivity)
-keep class me.musify.MainActivity { *; }

# Keep all classes referenced in AndroidManifest.xml
-keep class * extends android.app.Activity
-keepclassmembers class * extends android.app.Activity {
    public void *(android.view.View);
}

# just_audio plugin
-keep class com.ryanheise.just_audio.** { *; }
-dontwarn com.ryanheise.just_audio.**

# ExoPlayer (used by just_audio)
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# Notification and notification channels (Android 8.0+)
-keep class android.app.Notification { *; }
-keep class android.app.NotificationChannel { *; }
-keep class android.app.NotificationManager { *; }
-keep class androidx.core.app.NotificationCompat { *; }
-keep class androidx.core.app.NotificationCompat$* { *; }

# Keep notification builder and style classes
-keep class androidx.core.app.NotificationCompat$Builder { *; }
-keep class androidx.core.app.NotificationCompat$MediaStyle { *; }
-keep class androidx.media.app.NotificationCompat$MediaStyle { *; }

# HTTP and networking
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }
-dontwarn okhttp3.**
-dontwarn retrofit2.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Remove logging
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# Flutter embedding
-keep class io.flutter.embedding.** { *; }

# Gson (if used)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# General optimizations
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose