plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ayrlin.holodex_notifier"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.ayrlin.holodex_notifier"
        minSdk = Math.max(flutter.minSdkVersion,26)
        targetSdk = Math.max(flutter.targetSdkVersion,35)
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            storeFile = file("holodex-notifier.keystore") 
            storePassword = "ayrlindification"     
            keyAlias = "alpha-0.1.0"                 
            keyPassword = "ayrlindification"      
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:1.2.2")
}

flutter {
    source = "../.."
}