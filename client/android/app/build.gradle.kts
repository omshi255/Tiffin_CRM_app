import java.util.Properties

plugins {
id("com.android.application")
id("kotlin-android")
id("dev.flutter.flutter-gradle-plugin")
id("com.google.gms.google-services")
}

fun loadGoogleMapsKeyFromEnv(): String {
    val clientRoot = rootProject.projectDir.parentFile
    val envFile = clientRoot.resolve(".env")
    if (envFile.exists()) {
        envFile.readLines().forEach { line ->
            val t = line.trim()
            if (t.startsWith("GOOGLE_MAPS_API_KEY=")) {
                return t.removePrefix("GOOGLE_MAPS_API_KEY=").trim()
                    .trim('"')
            }
        }
    }
    val local = clientRoot.resolve("android/local.properties")
    if (local.exists()) {
        val p = Properties()
        local.inputStream().use { p.load(it) }
        p.getProperty("GOOGLE_MAPS_API_KEY")?.let { if (it.isNotBlank()) return it.trim() }
    }
    return "YOUR_GOOGLE_MAPS_API_KEY"
}

/** Truecaller OAuth Client ID: same pattern as Maps — read from `client/.env` or `android/local.properties`. */
fun loadTruecallerClientIdFromEnv(): String {
    val clientRoot = rootProject.projectDir.parentFile
    val envFile = clientRoot.resolve(".env")
    if (envFile.exists()) {
        envFile.readLines().forEach { line ->
            val t = line.trim()
            if (t.startsWith("TRUECALLER_CLIENT_ID=")) {
                return t.removePrefix("TRUECALLER_CLIENT_ID=").trim()
                    .trim('"')
            }
        }
    }
    val local = clientRoot.resolve("android/local.properties")
    if (local.exists()) {
        val p = Properties()
        local.inputStream().use { p.load(it) }
        p.getProperty("TRUECALLER_CLIENT_ID")?.let { if (it.isNotBlank()) return it.trim() }
    }
    return "YOUR_TRUECALLER_CLIENT_ID"
}

android {
namespace = "com.tiffin.crm.tiffin_crm"
compileSdk = flutter.compileSdkVersion
ndkVersion = flutter.ndkVersion


compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
    isCoreLibraryDesugaringEnabled = true
}

kotlinOptions {
    jvmTarget = "17"
}

defaultConfig {
    applicationId = "com.tiffin.crm.tiffin_crm"
    // Truecaller OAuth SDK requires at least API 21.
    minSdk = maxOf(21, flutter.minSdkVersion)
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
    manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = loadGoogleMapsKeyFromEnv()
    manifestPlaceholders["TRUECALLER_CLIENT_ID"] = loadTruecallerClientIdFromEnv()
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("debug")
    }
}


}

dependencies {
coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
source = "../.."
}
