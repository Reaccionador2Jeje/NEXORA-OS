# NEXORA Minimal installed profile

Choose **NEXORA Minimal (solo sistema base)** in the native GTK installer's desktop profile selector.

The ISO boots a temporary Openbox + GTK3 environment solely to run the NEXORA installer. The installer removes Openbox, LightDM and Xorg from the installed target and sets the system to boot to multi-user.target (terminal login).

The temporary graphical installer environment is not retained in the installed Minimal system. NetworkManager remains enabled.
