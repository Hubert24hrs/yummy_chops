import java.util.Properties

// Google Maps key for Android, never committed: android/local.properties (MAPS_API_KEY=...) or env MAPS_API_KEY.
val mapsApiKey: String = Properties().run {
    val file = rootProject.file("local.properties")
    if (file.exists()) file.inputStream().use { load(it) }
    getProperty("MAPS_API_KEY") ?: System.getenv("MAPS_API_KEY") ?: ""
}

// Test builds that reach a laptop over the local Wi-Fi use plain http: only builds made with
// GUDMEAL_ALLOW_CLEARTEXT=true allow it (debug builds always do; store builds never do).
val allowCleartext: String = if (System.getenv("GUDMEAL_ALLOW_CLEARTEXT") == "true") "true" else "false"

// The upload key for store builds, never committed: android/key.properties with storeFile (a path from android/app),
// storePassword, keyAlias and keyPassword. Without that file a release build is signed with the debug key, which is
// what the test builds use.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val hasUploadKey: Boolean = keystoreProperties.getProperty("storeFile") != null

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.yummy247.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // The store identity: permanent after the first Play Store upload (owner's choice, 25 Nov 2026).
        applicationId = "com.yummy247.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["usesCleartextTraffic"] = allowCleartext
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    signingConfigs {
        if (hasUploadKey) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        debug {
            manifestPlaceholders["usesCleartextTraffic"] = "true"
        }
        release {
            // The upload key when android/key.properties exists (store builds); the debug key otherwise, so test
            // builds and `flutter run --release` work without a keystore.
            signingConfig = signingConfigs.getByName(if (hasUploadKey) "release" else "debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // AppCompat themes (styles.xml): the fingerprint prompt (local_auth) needs them on older Android versions.
    implementation("androidx.appcompat:appcompat:1.7.0")
}
