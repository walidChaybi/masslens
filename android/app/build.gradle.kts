import java.io.FileInputStream
import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

dependencies {
    implementation("com.google.android.gms:play-services-mlkit-subject-segmentation:16.0.0-beta1")
    testImplementation("junit:junit:4.13.2")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use(keystoreProperties::load)
}

val buildingRelease = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
val dartDefines = providers.gradleProperty("dart-defines").orNull
    ?.split(",")
    ?.filter { it.isNotBlank() }
    ?.associate { encoded ->
        val decoded = String(Base64.getDecoder().decode(encoded))
        val separator = decoded.indexOf('=')
        check(separator > 0) { "Invalid --dart-define passed to release build." }
        decoded.substring(0, separator) to decoded.substring(separator + 1)
    }
    .orEmpty()

if (buildingRelease) {
    val requiredDefines = listOf(
        "MASSLENS_API_URL",
        "MASSLENS_PRIVACY_URL",
        "ADMOB_NATIVE_AD_UNIT_ID",
        "ADMOB_REWARDED_AD_UNIT_ID",
        "ADMOB_INTERSTITIAL_AD_UNIT_ID",
        "ADMOB_APP_OPEN_AD_UNIT_ID",
    )
    check(dartDefines["ADMOB_ENABLED"] == "true") {
        "Release builds require --dart-define=ADMOB_ENABLED=true."
    }
    check(dartDefines["ADMOB_USE_TEST_IDS"] == "false") {
        "Release builds require --dart-define=ADMOB_USE_TEST_IDS=false."
    }
    for (name in requiredDefines) {
        val value = dartDefines[name].orEmpty()
        check(value.isNotBlank() && !value.contains("3940256099942544")) {
            "Release builds require a live $name."
        }
    }
    check(dartDefines.getValue("MASSLENS_API_URL").startsWith("https://")) {
        "MASSLENS_API_URL must use HTTPS."
    }
    val privacyPolicyUrl = dartDefines.getValue("MASSLENS_PRIVACY_URL")
    check(
        privacyPolicyUrl.startsWith("https://") &&
            !privacyPolicyUrl.contains(".example") &&
            !privacyPolicyUrl.contains("localhost")
    ) {
        "MASSLENS_PRIVACY_URL must be a public HTTPS URL, not a placeholder."
    }
}

android {
    namespace = "com.masslens.mass_lens"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // New application identity for the photo-estimation app.
        applicationId = "com.lilai.masslens.photoestimates"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Google's official test App ID is the safe default. Set ADMOB_APP_ID
        // in android/gradle.properties before a production ads build.
        val adMobAppId = providers.gradleProperty("ADMOB_APP_ID")
            .getOrElse("ca-app-pub-3940256099942544~3347511713")
        if (buildingRelease) {
            check(!adMobAppId.contains("3940256099942544")) {
                "Release builds require a live ADMOB_APP_ID Gradle property."
            }
        }
        manifestPlaceholders["admobAppId"] = adMobAppId
        manifestPlaceholders["massLensAppLabel"] = "MassLens"
    }

    signingConfigs {
        create("release") {
            check(keystorePropertiesFile.exists()) {
                "Missing android/key.properties for the release signing key."
            }
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".archeck"
            manifestPlaceholders["massLensAppLabel"] = "MassLens Debug"
        }
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
