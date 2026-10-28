# Sentry
-keep class io.sentry.** { *; }
-keep class io.sentry.android.** { *; }
-dontwarn io.sentry.**

# Keep your application classes that will be serialized/deserialized over Gson
-keep class sk.anickaapavol.organista.models.** { *; }

# Prevent R8 from leaving Data object members always null
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Prevent proguard from stripping interface information from TypeAdapter, TypeAdapterFactory,
# JsonSerializer, JsonDeserializer instances (so they can be used in @JsonAdapter)
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer


# Keep setters in Views so that animations can still work.
-keepclassmembers public class * extends android.view.View {
    void set*(***);
    *** get*();
}

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelables
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

# Keep custom application class
-keep class sk.anickaapavol.organista.** { *; }

# Keep Kotlin Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}

# Native debug symbols
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes Deprecated
-keepattributes DeprecatedSinceApi
-keepattributes DeprecatedUntilApi
-keepattributes DeprecatedSinceApi,DeprecatedUntilApi
-keepattributes DeprecatedSinceApi,DeprecatedUntilApi,Deprecated
-keepattributes DeprecatedSinceApi,DeprecatedUntilApi,Deprecated,InnerClasses
-keepattributes DeprecatedSinceApi,DeprecatedUntilApi,Deprecated,InnerClasses,Signature
-keepattributes DeprecatedSinceApi,DeprecatedUntilApi,Deprecated,InnerClasses,Signature,Exceptions
-keepattributes DeprecatedSinceApi,DeprecatedUntilApi,Deprecated,InnerClasses,Signature,Exceptions,SourceFile
-keepattributes DeprecatedSinceApi,DeprecatedUntilApi,Deprecated,InnerClasses,Signature,Exceptions,SourceFile,LineNumberTable 