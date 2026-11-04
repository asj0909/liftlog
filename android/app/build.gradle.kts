import java.io.FileInputStream
import java.io.InputStreamReader
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// リリース（ストア提出用）の署名情報。android/key.properties に置き、Git には含めない。
// ファイルがなければ debug 署名にフォールバックする（手元で release を試すため）。
// ファイルはあるのに項目が足りないときは、release のビルド時だけエラーにする（debug や Gradle Sync は止めない）。
// 作り方は tool/create_upload_key.sh を参照。
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    // パスワードに日本語などが含まれても読めるよう UTF-8 で読む
    InputStreamReader(FileInputStream(keystorePropertiesFile), Charsets.UTF_8).use {
        keystoreProperties.load(it)
    }
}
val requiredSigningKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val missingSigningKeys = requiredSigningKeys.filter {
    keystoreProperties.getProperty(it).isNullOrBlank()
}
val hasUploadKey = keystorePropertiesFile.exists() && missingSigningKeys.isEmpty()

if (keystorePropertiesFile.exists() && missingSigningKeys.isNotEmpty()) {
    gradle.taskGraph.whenReady {
        if (allTasks.any { it.name.contains("Release") }) {
            throw GradleException(
                "android/key.properties に次の項目がありません：${missingSigningKeys.joinToString()}",
            )
        }
    }
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
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
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
