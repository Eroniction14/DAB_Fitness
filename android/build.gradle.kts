allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Some plugins (e.g. agora_rtc_engine) still compile against old Android APIs.
// Raise any Android library below API 36 up to 36; never lower newer ones.
// Must come before evaluationDependsOn(":app") below.
subprojects {
    val raiseCompileSdk: Project.() -> Unit = {
        extensions.findByType(com.android.build.api.dsl.LibraryExtension::class.java)
            ?.let { android ->
                val current = android.compileSdk ?: 0
                if (current < 36) android.compileSdk = 36
            }
    }
    if (state.executed) raiseCompileSdk() else afterEvaluate { raiseCompileSdk() }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
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