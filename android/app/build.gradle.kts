plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.harsh.kharcha"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.harsh.kharcha"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }
    
    testOptions {
        unitTests {
            isIncludeAndroidResources = true
            all {
                // Use JUnit Platform for Kotest property tests
                // But also support JUnit 4 for Robolectric tests
                it.useJUnitPlatform {
                    // Include JUnit 4 tests as well
                    includeEngines("junit-vintage")
                }
            }
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // WorkManager for background task scheduling
    implementation("androidx.work:work-runtime-ktx:2.9.0")
    
    // Testing dependencies
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.json:json:20231013")
    
    // Mockito for mocking
    testImplementation("org.mockito:mockito-core:5.8.0")
    testImplementation("org.mockito:mockito-inline:5.2.0")
    
    // Kotest for property-based testing
    testImplementation("io.kotest:kotest-runner-junit5:5.8.0")
    testImplementation("io.kotest:kotest-assertions-core:5.8.0")
    testImplementation("io.kotest:kotest-property:5.8.0")
    
    // JUnit Vintage engine for running JUnit 4 tests with JUnit 5 platform
    testImplementation("org.junit.vintage:junit-vintage-engine:5.10.1")
    
    // Robolectric for Android unit testing
    testImplementation("org.robolectric:robolectric:4.11.1")
}
