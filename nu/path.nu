let os_name = ($nu.os-info | get name);
match $os_name {
    "windows" => {
    },
    "macos" => {
        # --- append to path ---
        # $env.PATH = ($env.PATH | split row (char esep) | append "/path/to/your/new/directory")
        # --- prepend to path ---
        # $env.PATH = ($env.PATH | split row (char esep) | prepend "/path/to/your/new/directory")

        $env.PATH = (
            $env.PATH
            | split row (char esep)
            | append "~/.local/bin/"
            | append "/usr/local/bin/"
            | append "/opt/homebrew/bin/"
        )
    },
    "linux" => {
    },
    _ => {
        print $"Running on an unknown OS: ($os_name)"
    }
}
