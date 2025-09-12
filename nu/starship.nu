# Ensure Starship init file exists, else create it, then load it.
# let init_path = ("~/.cache/starship/init.nu" | path expand)
# if not ($init_path | path exists) {
#     print --stderr $"[info] Creating Starship init file at: ($init_path)"
#     mkdir ($init_path | path dirname)
#     starship init nu | save -f $init_path
# }

use ~/.cache/starship/init.nu
