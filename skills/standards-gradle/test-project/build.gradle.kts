/*
 * Gradle Standards Test Project - Build Script
 *
 * This build script demonstrates all the patterns covered in the standards-gradle skill.
 * Each section corresponds to a section in the skill documentation.
 */

// ============================================================================
// Section 1: Project Configuration
// ============================================================================

// --- Plugin Application ---
plugins {
    // Core plugins (no version needed)
    java
    application

    // External plugins from version catalog
    alias(libs.plugins.shadow) apply false

    // Alternative: Direct version (commented out - prefer version catalog)
    // id("com.github.johnrengelman.shadow") version "8.1.1" apply false
}

// --- Repository Configuration ---
repositories {
    mavenCentral()

    // Example: Custom repository (commented out)
    // maven {
    //     url = uri("https://example.com/maven")
    // }
}

// --- Dependency Management ---
dependencies {
    // GOOD: Using version catalog (type-safe, centralized versions)
    implementation(libs.guava)
    testImplementation(libs.bundles.testing)
    testRuntimeOnly(libs.junit.platform.launcher)

    // Example: Compile-only dependency
    compileOnly(libs.lombok)

    // Example: Runtime-only dependency
    runtimeOnly(libs.h2)

    // Alternative: Direct dependency notation (commented out - prefer version catalog)
    // implementation("com.google.guava:guava:33.0.0-jre")
    // testImplementation("org.junit.jupiter:junit-jupiter:5.10.2")
}

// --- Java Configuration ---
java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

// --- Application Configuration ---
application {
    mainClass = "com.example.Main"
}

// --- Test Configuration ---
tasks.named<Test>("test") {
    useJUnitPlatform()
}

// ============================================================================
// Section 2: Plugin/Task Development Examples
// ============================================================================

// --- Custom Task: Registering vs Creating ---

// GOOD: Lazy task registration
tasks.register("exampleTask") {
    doLast {
        println("Example task executed")
    }
}

// --- Custom Task: With Inputs and Outputs ---

// Abstract task class for proper input/output handling
abstract class ProcessFilesTask : DefaultTask() {
    @get:InputDirectory
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val inputDir: DirectoryProperty

    @get:OutputDirectory
    abstract val outputDir: DirectoryProperty

    @TaskAction
    fun process() {
        println("Processing files from ${inputDir.get()} to ${outputDir.get()}")
        // Actual processing logic would go here
    }
}

// Register task with typed properties
tasks.register<ProcessFilesTask>("processFiles") {
    inputDir = layout.projectDirectory.dir("src/main/resources")
    outputDir = layout.buildDirectory.dir("processed")
}

// --- Cacheable Task Example ---

// GOOD: Task marked as cacheable with proper input/output annotations
@CacheableTask
abstract class CacheableProcessTask : DefaultTask() {

    @get:InputDirectory
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val sourceDir: DirectoryProperty

    @get:Input
    abstract val processMode: Property<String>

    @get:OutputFile
    abstract val outputFile: RegularFileProperty

    init {
        // Set default values
        processMode.convention("count")
    }

    @TaskAction
    fun process() {
        val source = sourceDir.get().asFile
        val output = outputFile.get().asFile

        output.parentFile.mkdirs()

        when (processMode.get()) {
            "count" -> {
                val fileCount = source.walkTopDown().filter { it.isFile }.count()
                output.writeText("Found $fileCount files in ${source.name}")
            }
            "list" -> {
                val files = source.walkTopDown()
                    .filter { it.isFile }
                    .map { it.relativeTo(source).path }
                    .joinToString("\n")
                output.writeText("Files:\n$files")
            }
            else -> {
                output.writeText("Unknown mode: ${processMode.get()}")
            }
        }

        println("Processed ${source.name} in '${processMode.get()}' mode -> ${output.name}")
    }
}

// Register cacheable task for demonstration
tasks.register<CacheableProcessTask>("cacheableTask") {
    sourceDir = layout.projectDirectory.dir("src")
    processMode = "count"
    outputFile = layout.buildDirectory.file("cache-demo.txt")
}

// Task to validate caching works (run twice to see FROM-CACHE)
tasks.register("validateCache") {
    dependsOn("cacheableTask")
    doLast {
        val outputFile = layout.buildDirectory.file("cache-demo.txt").get().asFile
        if (outputFile.exists()) {
            println("Cache validation output:")
            println(outputFile.readText())
        } else {
            throw GradleException("Cacheable task did not produce output")
        }
    }
}

// --- Extension Example ---
// Note: For complex extensions, define them in buildSrc (see buildSrc/src/main/kotlin/)
// Simple inline extensions can be created with basic properties:

// Example: Extension with simple properties (for demonstration)
// Real extensions would be defined in buildSrc for type-safety and reusability

// --- Providers API Example ---

// Create a provider with lazy evaluation
val messageProvider: Provider<String> = providers.provider {
    "Message generated at configuration time"
}

// Create a property that can be set
val enabledProperty: Property<Boolean> = objects.property(Boolean::class.java).apply {
    convention(true)
}

// Task using provider (lazy configuration)
tasks.register("printMessage") {
    doLast {
        if (enabledProperty.get()) {
            println(messageProvider.get())
        }
    }
}

// --- Task Dependencies ---
tasks.register("taskA") {
    doLast { println("Task A") }
}

tasks.register("taskB") {
    dependsOn("taskA")
    doLast { println("Task B") }
}

tasks.register("taskC") {
    mustRunAfter("taskB")
    doLast { println("Task C") }
}

// ============================================================================
// Version Catalog Example
// ============================================================================

// Version catalog is now actively used above!
// See gradle/libs.versions.toml for centralized version management.
// Benefits:
// - Type-safe dependency accessors (libs.guava, libs.junit.jupiter)
// - Centralized version management across modules
// - IDE auto-completion support
// - Bundles group related dependencies (libs.bundles.testing)

// ============================================================================
// Build Cache Configuration Example
// ============================================================================

// Build cache can be enabled via gradle.properties or command line:
// org.gradle.caching=true
// or: ./gradlew build --build-cache

// Configuration cache can be enabled via:
// org.gradle.configuration-cache=true
// or: ./gradlew build --configuration-cache
