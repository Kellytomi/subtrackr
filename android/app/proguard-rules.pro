# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter rendering and UI components
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.rendering.** { *; }
-keep class io.flutter.ui.** { *; }
-keep class io.flutter.animation.** { *; }
-keep class io.flutter.painting.** { *; }

# Material Components
-keep class io.flutter.material.** { *; }
-keep class io.flutter.widgets.** { *; }

# Keep specific Flutter widgets
-keep class **.card.** { *; }
-keep class **.widget.Card { *; }
-keep class **.material.Card { *; }
-keep class **.widgets.Card { *; }

# Keep all model classes and their members
-keep class **.model.** { *; }
-keep class **.models.** { *; }
-keep class **.entity.** { *; }
-keep class **.entities.** { *; }

# Keep all providers and state management classes
-keep class **.provider.** { *; }
-keep class **.providers.** { *; }
-keep class **.bloc.** { *; }
-keep class **.blocs.** { *; }
-keep class **.state.** { *; }
-keep class **.states.** { *; }

# Keep all widget classes and their properties
-keepclassmembers class **.widget.** {
    *;
}
-keepclassmembers class **.widgets.** {
    *;
}
-keepclassmembers class **.screen.** {
    *;
}
-keepclassmembers class **.screens.** {
    *;
}

# Keep all service classes
-keep class **.service.** { *; }
-keep class **.services.** { *; }

# Keep all repository classes
-keep class **.repository.** { *; }
-keep class **.repositories.** { *; }

# Keep all utility classes
-keep class **.util.** { *; }
-keep class **.utils.** { *; }

# Keep all constants
-keep class **.constant.** { *; }
-keep class **.constants.** { *; }

# Keep all annotations
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes RuntimeVisible*Annotations*
-keepattributes InnerClasses

# Keep all serializable classes
-keepattributes Signature
-keep class * implements java.io.Serializable { *; }

# Keep all enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep all getters and setters
-keepclassmembers class * {
    void set*(***);
    *** get*();
    <init>(...);
}

# Keep Kotlin Coroutines
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# Keep ScrollView and ListView related classes
-keep class androidx.core.widget.** { *; }
-keep class androidx.recyclerview.widget.** { *; }

# Keep Material Design Components
-keep class com.google.android.material.** { *; }
-dontwarn com.google.android.material.**
-keep class androidx.compose.material.** { *; }

# Keep Animation Classes
-keep class android.animation.** { *; }
-keep class android.view.animation.** { *; }
-keep class androidx.transition.** { *; }

# Keep Dart-specific classes
-keep class dev.flutter.** { *; }
-keep class dart.** { *; }

# Keep Flutter entry points
-keep class * {
    @dev.flutter.annotation.pragma <methods>;
}

# Keep your app's specific classes
-keep class com.kelvin.subtrackr.** { *; }
-keepclassmembers class com.kelvin.subtrackr.** { *; }

# Keep all classes that might be used in JSON parsing
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep all classes that have native callbacks
-keep class * implements io.flutter.plugin.common.MethodChannel.MethodCallHandler { *; }
-keep class * implements io.flutter.plugin.common.EventChannel.StreamHandler { *; }
-keep class * implements io.flutter.plugin.platform.PlatformView { *; }

# Keep all classes that are referenced by Flutter plugins
-keep class androidx.lifecycle.** { *; }
-keep class androidx.annotation.** { *; }

# Keep all classes that might be used in reflection
-keepattributes *Annotation*
-keepclassmembers class * {
    @org.json.JSONObject.* <methods>;
    @com.google.gson.* <methods>;
}

# Keep all classes that are used in XML layouts
-keep public class * extends android.view.View
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.preference.Preference
-keep public class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

# Keep all widget properties
-keepclassmembers class * extends android.view.View {
    *** get*();
    void set*(***);
}

# Keep Play Core classes for Flutter compatibility
-keep class com.google.android.play.core.tasks.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-dontwarn com.google.android.play.core.**

# Keep Flutter deferred components
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; } 