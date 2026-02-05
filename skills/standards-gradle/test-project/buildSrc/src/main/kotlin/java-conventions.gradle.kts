/**
 * Convention plugin for shared Java configuration
 * This demonstrates how to share configuration across modules
 */

plugins {
    java
}

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

repositories {
    mavenCentral()
}

testing {
    suites {
        val test by getting(JvmTestSuite::class) {
            useJUnitJupiter()
        }
    }
}

tasks.named<Test>("test") {
    useJUnitPlatform()
}
