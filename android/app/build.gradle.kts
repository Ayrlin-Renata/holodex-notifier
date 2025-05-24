plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ayrlin.holodex_notifier"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" //change to change ndk version (flutter.ndkVersion)

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
        minSdk = Math.max(flutter.minSdkVersion,27)
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}