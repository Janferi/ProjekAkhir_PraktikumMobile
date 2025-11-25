plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.tugasakhir"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.tugasakhir"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }

    // Aktifkan dukungan Java 8 dan core library desugaring
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    buildTypes {
    getByName("release") {
        isMinifyEnabled = false
        isShrinkResources = false
    }
}

}

dependencies {
    // Desugaring library untuk dukungan fitur Java 8 di Android
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // Kotlin standard library
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8")

    // Dependensi lain (tambahkan punyamu di bawah ini)
    // contoh:
    // implementation("androidx.core:core-ktx:1.10.1")
    // implementation("androidx.appcompat:appcompat:1.6.1")
}

flutter {
    source = "../.."
}
