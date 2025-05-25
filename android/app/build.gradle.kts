import java.util.Properties
import java.io.FileInputStream
import java.io.File

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.shadowteam.wallrio"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.shadowteam.wallrio"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    val keystoreProperties = Properties().apply {
        load(FileInputStream(file("../key.properties")))
    }

    signingConfigs {
        // debug {
        //     keyAlias = keystoreProperties['keyAlias'] as String
        //     keyPassword = keystoreProperties['keyPassword'] as String
        //     storeFile = file(keystoreProperties['storeFile']) as String
        //     storePassword = keystoreProperties['storePassword'] as String
        // }
        // release {
        //     keyAlias = System.getenv("SIGNING_KEY_ALIAS")
        //     keyPassword = System.getenv("SIGNING_KEY_PASSWORD")
        //     storeFile = file("../../keystore.jks")
        //     storePassword = System.getenv("SIGNING_STORE_PASSWORD")
        // }

        // create("debug") {
        //     keyAlias = keystoreProperties["keyAlias"] as String
        //     keyPassword = keystoreProperties["keyPassword"] as String
        //     storeFile = file(keystoreProperties["storeFile"] as String)
        //     storePassword = keystoreProperties["storePassword"] as String
        // }
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        getByName("debug") {
            signingConfig = signingConfigs.getByName("release")
        }
        getByName("release") {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            // useProguard false
            isShrinkResources = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    // ... other dependencies
}

flutter {
    source = "../.."
}
