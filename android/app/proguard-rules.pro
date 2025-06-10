# Keep Facebook Fresco/ImagePipeline classes
-keep class com.facebook.imagepipeline.** { *; }
-keep class com.facebook.fresco.** { *; }
-dontwarn com.facebook.imagepipeline.**
-dontwarn com.facebook.fresco.**

# Keep WebP support
-keep class com.facebook.imagepipeline.nativecode.** { *; }
-dontwarn com.facebook.imagepipeline.nativecode.**