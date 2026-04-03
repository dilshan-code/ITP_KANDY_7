allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")

    project.plugins.withId("com.android.library") {
        val android = project.extensions.getByName("android")
        try {
            val getNamespace = android.javaClass.methods.find { it.name == "getNamespace" }
            val setNamespace = android.javaClass.methods.find { it.name == "setNamespace" && it.parameterCount == 1 }

            if (getNamespace != null && setNamespace != null) {
                val currentNamespace = getNamespace.invoke(android)
                if (currentNamespace == null) {
                    val fallbackNamespace = project.group.toString().takeIf { it.isNotBlank() && it != "unspecified" }
                            ?: "com.plugin.missing.namespace.${project.name.replace("-", ".")}"
                    setNamespace.invoke(android, fallbackNamespace)
                }
            }
        } catch (e: Exception) {
            // Ignore if reflection fails
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
