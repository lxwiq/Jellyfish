plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.lxwiq.jellyfish"
    // Override Flutter default to satisfy plugins requiring API 36
    compileSdk = 36
    // Override Flutter default NDK to satisfy plugins requiring NDK 27
    ndkVersion = "27.0.12077973"

    compileOptions {
        // Use Java 17 as recommended by AGP 8.x
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        // Align Kotlin JVM target with Java 17
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.lxwiq.jellyfish"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")

            // Optimisation R8: Minification et obfuscation du code
            isMinifyEnabled = true
            // Optimisation: Suppression des ressources inutilisées
            isShrinkResources = true

            // Règles ProGuard/R8
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // Optimisation: Split APK par ABI pour réduire la taille de téléchargement
    // Note: Ceci est utilisé uniquement pour les APKs, pas pour les AAB
    // Désactivé car cela cause des conflits lors de la construction d'AAB
    // Les AAB gèrent automatiquement l'optimisation multi-ABI via Google Play
    // splits {
    //     abi {
    //         isEnable = true
    //         reset()
    //         include("armeabi-v7a", "arm64-v8a", "x86_64")
    //         isUniversalApk = false  // Ne pas créer d'APK universel (trop gros)
    //     }
    // }

    // Optimisation: Exclusion des fichiers dupliqués
    packagingOptions {
        resources.excludes.add("META-INF/DEPENDENCIES")
        resources.excludes.add("META-INF/LICENSE")
        resources.excludes.add("META-INF/LICENSE.txt")
        resources.excludes.add("META-INF/license.txt")
        resources.excludes.add("META-INF/NOTICE")
        resources.excludes.add("META-INF/NOTICE.txt")
        resources.excludes.add("META-INF/notice.txt")
        resources.excludes.add("META-INF/*.kotlin_module")
}
}

// Suppress obsolete -source/-target warnings from Java compilation
tasks.withType<org.gradle.api.tasks.compile.JavaCompile>().configureEach {
    // AGP doesn't support --release flag; use sourceCompatibility/targetCompatibility instead
    // Suppress warnings about obsolete -source/-target options
    options.compilerArgs.add("-Xlint:-options")
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
