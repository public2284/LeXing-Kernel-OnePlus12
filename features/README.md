# features/ — Feature Registry

One YAML record per candidate feature, organized by area (root/, susfs/, mount/,
filesystem/, memory/, scheduler/, network/, debugging/, experimental/). A
feature appears here **before** any patch exists; appearing in the registry is
not approval to build it in.

Required fields (validated by build/checks/manifest_schema.sh):

    id: root/sukisu-ultra
    name: SukiSU Ultra
    description: what it actually does
    source: upstream repo + license
    type: compile-time | runtime | hybrid
    default_state: enabled | disabled
    risk: low | medium | high
    enable: how it is turned on
    disable: how it is turned off
    rollback: how it is undone

Plus the review fields the spec demands: dependencies, conflicts, kconfig
requirements, compatibility, and whether the feature is verified on this
device. A feature that cannot be disabled or rolled back must say so plainly.
Compile-time features become build profile fragments; runtime features belong to
the installer, and the two must never be conflated.
