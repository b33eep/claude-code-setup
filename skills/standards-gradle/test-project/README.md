# Gradle Standards Test Project

This test project validates all code examples from the `standards-gradle` skill. Every code snippet in the skill documentation should be tested here before being included.

## Project Information

- **Gradle Version:** 9.3.1 (Gradle 9 LTS)
- **Java Version:** 21
- **Purpose:** Validate skill code examples

## Project Structure

```
test-project/
├── build.gradle.kts          # Main build script with examples
├── settings.gradle.kts       # Project settings
├── gradle/                   # Gradle wrapper files
├── gradlew                   # Gradle wrapper script (Unix)
├── gradlew.bat               # Gradle wrapper script (Windows)
├── buildSrc/                 # Custom plugins and conventions
│   ├── build.gradle.kts
│   └── src/main/kotlin/
│       ├── ExamplePlugin.kt           # Custom plugin example
│       └── java-conventions.gradle.kts # Convention plugin
└── src/
    └── main/java/
        └── com/example/Main.java
```

## What's Included

### Section 1: Project Configuration Examples

- ✅ Plugin application (`plugins {}` block)
- ✅ Repository configuration (`repositories {}`)
- ✅ Dependency management (implementation, compileOnly, runtimeOnly, testImplementation)
- ✅ Java toolchain configuration
- ✅ Application plugin setup
- ✅ Test configuration with JUnit Platform

### Section 2: Plugin/Task Development Examples

- ✅ Lazy task registration (`tasks.register()`)
- ✅ Custom task with input/output annotations (`ProcessFilesTask`)
- ✅ Providers API usage (Provider<T>, Property<T>)
- ✅ Task dependencies (dependsOn, mustRunAfter)
- ✅ Custom plugin in buildSrc (`ExamplePlugin`)
- ✅ Extension API (`ExamplePluginExtension`)
- ✅ Convention plugin (`java-conventions.gradle.kts`)

## How to Validate Code Snippets

### 1. Basic Validation

Run `./gradlew tasks` to ensure the build script is valid:

```bash
./gradlew tasks
```

Expected: Should list all available tasks without errors.

### 2. Build the Project

```bash
./gradlew build
```

Expected: Successful build with all tests passing.

### 3. Run Custom Tasks

Test custom task examples:

```bash
# Test lazy task registration
./gradlew exampleTask

# Test task with inputs/outputs
./gradlew processFiles

# Test provider API
./gradlew printMessage

# Test task dependencies
./gradlew taskC

# Test custom plugin task
./gradlew examplePluginTask
```

### 4. Run the Application

```bash
./gradlew run
```

Expected: Prints Java version and message.

### 5. Test Configuration Cache

```bash
./gradlew build --configuration-cache
```

Expected: Build succeeds and subsequent builds show "Reusing configuration cache."

### 6. Test Build Cache

Test that build cache actually works with cacheable tasks:

```bash
# First run - task executes
./gradlew cacheableTask --build-cache

# Clean and run again - should hit cache
./gradlew clean cacheableTask --build-cache
```

Expected: Second run shows "FROM-CACHE" for cacheableTask.

To validate cache behavior visually:

```bash
# Run with info logging to see cache hits
./gradlew clean cacheableTask --build-cache --info | grep -i cache

# Verify output file was created
cat build/cache-demo.txt
```

Test full build caching:

```bash
./gradlew clean build --build-cache
./gradlew clean build --build-cache
```

Expected: Second build shows "FROM-CACHE" for many tasks including compile, test, jar.

## Adding New Code Examples

When adding new code examples to the skill:

1. **Add to `build.gradle.kts`**: Place the example in the appropriate section
2. **Test it**: Run `./gradlew tasks` to ensure no syntax errors
3. **Verify behavior**: Run the specific task or build to verify it works
4. **Document**: Add notes about what the example demonstrates

## Code Snippet Template

When writing examples for the skill, use this format:

```kotlin
// BAD - eager task creation (avoid this)
tasks.create("myTask") {
    doLast { ... }
}

// GOOD - lazy task registration (prefer this)
tasks.register("myTask") {
    doLast { ... }
}
```

Always include:
- ✅ A clear comment explaining what's being demonstrated
- ✅ Both BAD and GOOD examples where applicable
- ✅ Inline documentation for complex examples

## Testing Checklist

Before adding a code example to the skill, verify:

- [ ] Code runs without syntax errors
- [ ] Code follows Gradle 9 best practices
- [ ] Code is cache-compatible (if applicable)
- [ ] Code uses Kotlin DSL syntax (not Groovy)
- [ ] Code includes appropriate comments
- [ ] BAD examples are clearly marked as anti-patterns

## Version Catalog

This project uses version catalogs (Gradle's modern dependency management).

The catalog is defined in `gradle/libs.versions.toml`:

```toml
[versions]
guava = "33.0.0-jre"
junit = "5.10.2"

[libraries]
guava = { module = "com.google.guava:guava", version.ref = "guava" }
junit-jupiter = { module = "org.junit.jupiter:junit-jupiter", version.ref = "junit" }

[plugins]
shadow = { id = "com.github.johnrengelman.shadow", version = "8.1.1" }
```

And used in `build.gradle.kts`:

```kotlin
dependencies {
    implementation(libs.guava)         // Type-safe accessor
    testImplementation(libs.bundles.testing)
}
```

To verify version catalog works:

```bash
./gradlew dependencies | grep guava
```

Expected: Shows guava dependency resolved from version catalog.

## Troubleshooting

### Gradle daemon issues

```bash
./gradlew --stop
./gradlew tasks
```

### Clean build

```bash
./gradlew clean build --no-build-cache --no-configuration-cache
```

### Verify wrapper version

```bash
./gradlew --version
```

Expected: Gradle 9.3.1

## References

- [Gradle 9 Documentation](https://docs.gradle.org/9.3/userguide/userguide.html)
- [Kotlin DSL Primer](https://docs.gradle.org/current/userguide/kotlin_dsl.html)
- [Custom Tasks](https://docs.gradle.org/current/userguide/custom_tasks.html)
- [Custom Plugins](https://docs.gradle.org/current/userguide/custom_plugins.html)
