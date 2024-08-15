plugins {
    id("ca.stellardrift.gitpatcher") version "1.1.0"
}

gitPatcher.patchedRepos.create("geyser") {
    submodule.set("Geyser")
    target.set(file("patched-geyser"))
    patches.set(file("patches"))
}