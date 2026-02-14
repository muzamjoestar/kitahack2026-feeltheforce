import com.android.build.gradle.BaseExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
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

subprojects {
    afterEvaluate {
        // Cari Android extension (library/app)
        val androidExt = extensions.findByName("android") as? BaseExtension
        if (androidExt != null) {
            // AGP 8+ perlukan namespace. Kalau plugin tak set, kita set automatik.
            try {
                val getNs = androidExt::class.java.getMethod("getNamespace")
                val current = getNs.invoke(androidExt) as? String

                if (current.isNullOrBlank()) {
                    val setNs = androidExt::class.java.getMethod("setNamespace", String::class.java)
                    setNs.invoke(androidExt, project.group.toString())
                }
            } catch (_: Throwable) {
                // Kalau AGP lama / method tak wujud, ignore
            }
        }
    }
}
