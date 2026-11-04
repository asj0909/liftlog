import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// リリース（ストア提出用）の署名情報。android/key.properties に置き、Git には含めない。
// ファイルがなければ debug 署名にフォールバックする（手元で release を試すため）。
// 作り方は tool/create_upload_key.sh を参照。
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasUploadKey = keystorePropertiesFile.exists()
if (hasUploadKey) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ストア公開後は変更できない（変えると別アプリ扱いになる）
    namespace = "com.oojimarounin.liftlog"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.oojimarounin.liftlog"
        // SDK バージョンは Flutter SDK の既定値に従う（Flutter を上げると変わる。PROGRESS.md 参照）
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // バージョンは pubspec.yaml の version（例：1.0.0+1 → versionName 1.0.0 / versionCode 1）
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasUploadKey) {
            create("upload") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasUploadKey) {
                signingConfigs.getByName("upload")
            } else {
                logger.warn("android/key.properties がないため、release を debug 署名でビルドします（ストアには提出できません）")
                signingConfigs.getByName("debug")
            }
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
