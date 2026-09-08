plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.io.FileInputStream
import java.util.Properties

val signingProperties = Properties()
val signingPropertiesFile = rootProject.file("key.properties")
if (signingPropertiesFile.exists()) {
    FileInputStream(signingPropertiesFile).use(signingProperties::load)
}

android {
    namespace = "com.shengyu.im.shengyu_ui_admin_im"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.shengyu.im.shengyu_ui_admin_im"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            check(signingPropertiesFile.exists()) {
                "Missing android/key.properties. Configure the release signing key before building a distributable APK."
            }
            keyAlias = signingProperties.getProperty("keyAlias")
            keyPassword = signingProperties.getProperty("keyPassword")
            storeFile = file(signingProperties.getProperty("storeFile"))
            storePassword = signingProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }

    // Flutter assets are not Android raw resources. Generate the native
    // CallKit ringtone resource from the single canonical sound file so the
    // foreground page and lock-screen incoming UI cannot drift apart.
    sourceSets.getByName("main").res.srcDir(
        layout.buildDirectory.dir("generated/call-sounds/res"),
    )
}

val prepareCallSounds by tasks.registering(Copy::class) {
    from(file("../../assets/sounds/call_ringtone.mp3"))
    into(layout.buildDirectory.dir("generated/call-sounds/res/raw"))
}

tasks.named("preBuild").configure {
    dependsOn(prepareCallSounds)
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
