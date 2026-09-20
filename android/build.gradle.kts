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
    if (project.name != "app") {
        afterEvaluate {
            val android = project.extensions.findByName("android")
            if (android != null) {
                var applied = false
                // Try compileSdkVersion(int)
                val intMethod = android.javaClass.methods.firstOrNull {
                    it.name == "compileSdkVersion" && it.parameterTypes.size == 1 &&
                    (it.parameterTypes[0] == Int::class.javaPrimitiveType || it.parameterTypes[0] == java.lang.Integer::class.java)
                }
                if (intMethod != null) {
                    try {
                        intMethod.invoke(android, 36)
                        applied = true
                    } catch (e: Exception) {}
                }

                // Try compileSdkVersion(String)
                if (!applied) {
                    val strMethod = android.javaClass.methods.firstOrNull {
                        it.name == "compileSdkVersion" && it.parameterTypes.size == 1 &&
                        it.parameterTypes[0] == String::class.java
                    }
                    if (strMethod != null) {
                        try {
                            strMethod.invoke(android, "android-36")
                            applied = true
                        } catch (e: Exception) {}
                    }
                }

                // Try setCompileSdk(Integer)
                val setCompileSdk = android.javaClass.methods.firstOrNull {
                    it.name == "setCompileSdk" && it.parameterTypes.size == 1
                }
                if (setCompileSdk != null) {
                    try {
                        setCompileSdk.invoke(android, 36)
                        applied = true
                    } catch (e: Exception) {}
                }

                if (applied) {
                    println("Successfully configured compileSdk=36 for ${project.name}")
                } else {
                    println("Could not configure compileSdk for ${project.name}")
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
