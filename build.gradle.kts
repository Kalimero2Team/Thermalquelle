plugins {
    id("ca.stellardrift.gitpatcher") version "1.1.0"
}

patches {
    submodule.set("Geyser")
    target.set(file("patched-geyser"))
    patches.set(file("patches"))
}