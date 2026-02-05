import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.DefaultTask
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.provider.Property
import org.gradle.api.tasks.*

/**
 * Example custom plugin demonstrating:
 * - Plugin implementation (Plugin<Project>)
 * - Extension API for configuration
 * - Custom task with proper inputs/outputs
 * - Providers API usage
 */
class ExamplePlugin : Plugin<Project> {
    override fun apply(project: Project) {
        // Create and register extension
        val extension = project.extensions.create("examplePlugin", ExamplePluginExtension::class.java)

        // Register custom task
        project.tasks.register("examplePluginTask", ExamplePluginTask::class.java) {
            // Connect task properties to extension properties (lazy configuration)
            message.set(extension.message)
            outputFile.set(project.layout.buildDirectory.file("example-output.txt"))
        }
    }
}

/**
 * Extension for configuring the ExamplePlugin
 * Uses Property<T> for lazy configuration
 */
abstract class ExamplePluginExtension {
    abstract val message: Property<String>

    init {
        // Set default value
        message.convention("Default message from plugin")
    }
}

/**
 * Custom task with proper input/output annotations for caching
 */
abstract class ExamplePluginTask : DefaultTask() {
    @get:Input
    abstract val message: Property<String>

    @get:OutputFile
    abstract val outputFile: RegularFileProperty

    @TaskAction
    fun execute() {
        val output = outputFile.get().asFile
        output.parentFile.mkdirs()
        output.writeText(message.get())
        println("Wrote message to: ${output.absolutePath}")
    }
}
