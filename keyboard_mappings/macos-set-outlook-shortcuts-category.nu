# Sets Outlook category keyboard shortcuts (Ctrl+Cmd+Fn) via macOS defaults.
# Backs up preferences first, then atomically replaces NSUserKeyEquivalents,
# preserving any non-F-key bindings and removing stale ones.

# Function key constants
let F1  = "\u{F704}"
let F2  = "\u{F705}"
let F3  = "\u{F706}"
let F4  = "\u{F707}"
let F5  = "\u{F708}"
let F6  = "\u{F709}"
let F7  = "\u{F70A}"
let F8  = "\u{F70B}"
let F9  = "\u{F70C}"
let F10 = "\u{F70D}"
let F11 = "\u{F70E}"
let F12 = "\u{F70F}"
let F13 = "\u{F710}"
let F14 = "\u{F711}"
let F15 = "\u{F712}"
let F16 = "\u{F713}"

# Category -> Function key mapping
let shortcuts = {
    "BTS/General":      $F1
    "BTS/Edu":          $F2
    "BTS/HR/General":   $F3
    "BTS/IT":           $F4

    "BTS/P&A":          $F5
    # "BTS/ZNA/General":  $F6
    "G/General":        $F7
    "CDO/General":      $F8

    "P/WCS3":           $F9
    "P/ZIPTotal":       $F10
    # "P/???":          $F11
    "P/DocUnd":         $F12

    "P/DP":             $F13
    "P/DP-Actuarial":   $F14
    "P/Snowflake":      $F15
    "Clear All":        $F16
}

# Backup
defaults export com.microsoft.Outlook ~/outlook-shortcuts-backup.plist

# Read existing non-F-key bindings to preserve
let preserved = (
    try {
        defaults read com.microsoft.Outlook NSUserKeyEquivalents
        | lines
        | where {|line| let t = ($line | str trim); $t != "{" and $t != "}" and $t != ""}
        | each {|line| $line | str trim | parse '"{key}" = "{val}";' | first}
        | where {|row| not ($row.val | str starts-with "@^")}
    } catch { [] }
)

# Build complete replacement: preserved non-F-key entries + new shortcuts
let all_pairs = (
    $preserved
    | each {|row| [$row.key, $row.val]}
    | append ($shortcuts | transpose category fkey | each {|row| [$row.category, $"@^($row.fkey)"]})
    | flatten
)

# Write atomically — replaces entire dict, stale F-key entries are gone
defaults write com.microsoft.Outlook NSUserKeyEquivalents -dict ...$all_pairs

# # Reload preferences
# killall cfprefsd

# # Restart Outlook if running
# killall "Microsoft Outlook"