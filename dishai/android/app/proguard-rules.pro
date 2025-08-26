###########################################################
# FLUTTER KURALLARI
###########################################################
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.plugins.**  { *; }

###########################################################
# GOOGLE PLAY SERVICES & FIREBASE
###########################################################
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

###########################################################
# GOOGLE ML KIT
###########################################################
# Tüm ML Kit sınıflarını koru (text recognition dahil)
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# İç yapılar (internal)
-keep class com.google.android.gms.internal.mlkit.** { *; }
-dontwarn com.google.android.gms.internal.mlkit.**

###########################################################
# TENSORFLOW LITE (GPU + Core)
###########################################################
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

###########################################################
# KÜTÜPHANEYE ÖZGÜ DİĞER PLUGINLER (opsiyonel güvenlik)
###########################################################
# (örnek: camera, geolocator, image_picker vs. için gerekirse açılır)
-dontwarn androidx.lifecycle.**
-dontwarn androidx.annotation.**
-dontwarn android.support.v4.**
