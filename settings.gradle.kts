pluginManagement {
    repositories {
        gradlePluginPortal()
    }
}

if (file("patched-geyser").exists()) {
    includeBuild("patched-geyser")
}

rootProject.name = "Thermalquelle"