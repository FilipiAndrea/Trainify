plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.trainify"
    compileSdk = flutter.compileSdkVersion

    // Aggiungi la versione dell'NDK richiesta dal plugin
    ndkVersion = "27.0.12077973" // Qui specifichi la versione NDK corretta

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specifica il tuo Application ID unico (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.trainify"
        // Puoi aggiornare i seguenti valori in base alle necessità della tua applicazione.
        // Per maggiori informazioni, consulta: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Aggiungi la tua configurazione di firma per la build di rilascio.
            // Per ora, uso la configurazione di debug, quindi `flutter run --release` funziona.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
