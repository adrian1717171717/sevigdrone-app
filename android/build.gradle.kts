buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Herramientas de construcción de Android
        classpath("com.android.tools.build:gradle:8.1.0")

        // --- ESTA ES LA LÍNEA QUE FALTABA (Plugin de Kotlin) ---
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0")

        // Plugin de Google Services (Firebase)
        classpath("com.google.gms:google-services:4.4.1")
    }
}

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
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}