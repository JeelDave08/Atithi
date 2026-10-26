pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        mavenCentral()
        gradlePluginPortal()
    }
}

gradle.allprojects {
    buildscript.repositories.all {
        if (this is MavenArtifactRepository) {
            val u = url.toString()
            if (u.contains("repo.maven.apache.org") || u.contains("repo1.maven.org")) {
                setUrl("https://maven.aliyun.com/repository/public")
            }
        }
    }
    buildscript.repositories {
        maven { url = uri("https://maven.aliyun.com/repository/public") }
    }
    repositories.all {
        if (this is MavenArtifactRepository) {
            val u = url.toString()
            if (u.contains("repo.maven.apache.org") || u.contains("repo1.maven.org")) {
                setUrl("https://maven.aliyun.com/repository/public")
            }
        }
    }
    repositories {
        maven { url = uri("https://maven.aliyun.com/repository/public") }
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") version("4.4.4") apply false
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

include(":app")
