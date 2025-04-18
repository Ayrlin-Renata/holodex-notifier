# Flutter default rules.
# -if { StackTraceElement floatFromDecimal(java.lang.String); }
-keep class io.flutter.embedding.** { *; }
-keep class androidx.lifecycle.** { *; }

# Add these rules for flutter_local_notifications and its dependencies:
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.gson.** { *; }
# Keep generic signatures for classes using TypeToken
-keepattributes Signature
-keep public class * extends com.google.gson.reflect.TypeToken

# --- Add this rule for Play Core ---
# Flutter engine references Play Core library classes optionally.
# If you are NOT using Play Feature Delivery, SplitCompat, or In-App Updates,
# it's safe to ignore warnings about these missing classes.
-dontwarn com.google.android.play.core.**
# ---------------------------------

# Add other rules specific to your project if needed...
