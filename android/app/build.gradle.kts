plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase plugins for cloud sync
    id("com.google.gms.google-services")
    // Firebase App Distribution for testing builds
    id("com.google.firebase.appdistribution")
}

import java.util.Properties
import java.io.FileInputStream
import org.gradle.jvm.toolchain.JavaLanguageVersion

// Load keystore properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.kelvin.subtrackr.v2"
    compileSdk = 35

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    // JVM Toolchain configuration
    java {
        toolchain {
            languageVersion.set(JavaLanguageVersion.of(17))
        }
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            } else {
                storeFile = file("keystore/subtrackr-keystore.jks")
                storePassword = System.getenv("KEYSTORE_PASSWORD") ?: ""
                keyAlias = "upload"
                keyPassword = System.getenv("KEY_PASSWORD") ?: ""
            }
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.kelvin.subtrackr.v2"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = 34
        // Version info is automatically read from pubspec.yaml by Flutter
        versionCode = flutter.versionCode?.toInt() ?: 1
        versionName = flutter.versionName ?: "1.0.0"
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Enable code shrinking, obfuscation, and optimization
            isMinifyEnabled = true
            // Enable resource shrinking
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("release")
            isDebuggable = false
            
            // Optimize NDK for size
            ndk {
                debugSymbolLevel = "SYMBOL_TABLE" // Smaller than FULL
                abiFilters += listOf("arm64-v8a") // Only support 64-bit ARM (most common)
            }
            
            // Additional packaging options for size optimization
            packagingOptions {
                resources {
                    excludes += listOf(
                        "/META-INF/{AL2.0,LGPL2.1}",
                        "/META-INF/versions/**",
                        "**/kotlin/**",
                        "**/*.kotlin_metadata",
                        "**/DebugProbesKt.bin"
                    )
                }
            }
            
            // Firebase App Distribution configuration
            configure<com.google.firebase.appdistribution.gradle.AppDistributionExtension> {
                releaseNotes = "New release for testing"
                groups = "Testers"  // You can create this group in Firebase Console
            }
        }
        debug {
            // For debug builds, disable both resource and code shrinking
            isMinifyEnabled = false
            isShrinkResources = false
            
            // Firebase App Distribution configuration
            configure<com.google.firebase.appdistribution.gradle.AppDistributionExtension> {
                releaseNotes = "Debug build for testing"
                groups = "Int-testers"
            }
        }
    }

    ndkVersion = "27.0.12077973"
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("org.jetbrains.kotlin:kotlin-stdlib:2.1.0")
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.annotation:annotation:1.7.1")
    
    // Firebase dependencies for cloud sync
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    
    // Multidex support for Android
    implementation("androidx.multidex:multidex:2.0.1")
    
    // Add Play Core dependencies (compatible with Android 14)
    implementation("com.google.android.play:feature-delivery:2.1.0")
    implementation("com.google.android.play:feature-delivery-ktx:2.1.0")
}

flutter {
    source = "../.."
}
