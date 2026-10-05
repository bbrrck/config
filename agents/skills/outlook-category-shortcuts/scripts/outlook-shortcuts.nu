#!/usr/bin/env nu
# Show / change Outlook category shortcuts (⌃⌘F1..F16) and their position on
# the VIA Megalodon pad (layer 2, 4x4 grid, row-major: F1 = row1/col1 ... F16 = row4/col4).
# Stored in macOS `defaults` domain com.microsoft.Outlook, key NSUserKeyEquivalents.

const DOMAIN = "com.microsoft.Outlook"
const F1_CODEPOINT = 0xF704 # NSF1FunctionKey; Fn = F1 + (n - 1)
const MODS = "@^" # @ = Cmd, ^ = Ctrl
const VIA_LAYER = 2

def fkey-char [n: int]: nothing -> string {
    char --integer ($F1_CODEPOINT + $n - 1)
}

def slot-pos [n: int]: nothing -> record {
    {layer: $VIA_LAYER, row: (($n - 1) // 4 + 1), col: (($n - 1) mod 4 + 1)}
}

def check-slot [n: int] {
    if $n < 1 or $n > 16 {
        error make {msg: $"slot must be 1-16, got ($n)"}
    }
}

# All NSUserKeyEquivalents as {category, value}
def read-raw []: nothing -> list<record<category: string, value: string>> {
    try {
        defaults export $DOMAIN -
        | plutil -extract NSUserKeyEquivalents json -o - -
        | from json
        | transpose category value
    } catch { [] }
}

# Bindings in the F-key scheme: {category, slot}
def read-slots []: nothing -> table {
    read-raw
    | each {|r|
        let slot = (
            1..16 | where {|n| $r.value == $"($MODS)(fkey-char $n)" } | first | default null
        )
        {category: $r.category, slot: $slot}
    }
}

def backup [] {
    let stamp = (date now | format date "%Y%m%d-%H%M%S")
    let path = ($nu.home-dir | path join $"outlook-shortcuts-backup-($stamp).plist")
    defaults export $DOMAIN $path
    print $"backup: ($path)"
}

# Replace the whole dict atomically (same approach as macos-set-outlook-shortcuts-category.nu)
def write-all [pairs: list<record<category: string, value: string>>] {
    let flat = ($pairs | each {|p| [$p.category $p.value]} | flatten)
    if ($flat | is-empty) {
        defaults delete $DOMAIN NSUserKeyEquivalents
    } else {
        defaults write $DOMAIN NSUserKeyEquivalents -dict ...$flat
    }
}

# VIA README holds the per-layer key meanings (single source of truth).
# Override with VIA_README; default is found relative to this script (works through symlinks).
def readme-path []: nothing -> string {
    $env.VIA_README? | default (
        $env.CURRENT_FILE? | default $nu.current-exe
        | path expand
        | path dirname | path dirname | path dirname | path dirname | path dirname
        | path join "keyboard_mappings" "via" "README.md"
    )
}

# Lines of "## Layer N: ..." section, heading included.
def layer-lines [n: int]: nothing -> list<string> {
    let all = (open --raw (readme-path) | lines)
    let hits = ($all | enumerate | where {|r| $r.item | str starts-with $"## Layer ($n):" })
    if ($hits | is-empty) {
        error make {msg: $"no '## Layer ($n):' section in (readme-path)"}
    }
    let rest = ($all | skip ($hits.0.index + 1))
    [($all | get $hits.0.index)] | append ($rest | take while {|l| not ($l | str starts-with "## ") })
}

# First markdown table after a marker line -> rows of cells (row label and header/separator dropped).
def parse-table [lines: list<string>, marker: string]: nothing -> list<list<string>> {
    $lines
    | skip until {|l| ($l | str trim) == $marker }
    | skip 1
    | skip until {|l| $l | str starts-with "|" }
    | take while {|l| $l | str starts-with "|" }
    | skip 2
    | each {|l| $l | str trim | split row "|" | skip 1 | drop 1 | each {|c| $c | str trim } | skip 1 }
}

# Show one layer: 4 rows x 5 cols (4 grid keys + side key). Layer 2 shows live Outlook categories.
def "main layer" [n: int, --json (-j)] {
    let lines = (layer-lines $n)
    let title = ($lines.0 | str replace "## " "")
    let actions = (parse-table $lines "Actions:")
    let keys = (parse-table $lines "Keyboard Shortcuts - MacOS keys:")
    let slots = (if $n == $VIA_LAYER { read-slots } else { [] })

    let rows = (
        0..3 | each {|r|
            0..4 | each {|c|
                let slot = $r * 4 + $c + 1
                let cat = (if $n == $VIA_LAYER and $c < 4 {
                    $slots | where slot == $slot | get category | first | default null
                } else { null })
                let is_cat_slot = ($n == $VIA_LAYER and $c < 4)
                {
                    action: (if $is_cat_slot { $cat | default "(free)" } else { $actions | get $r | get $c })
                    keys: ($keys | get $r | get $c)
                    dim: ($is_cat_slot and $cat == null)
                    side: ($c == 4)
                }
            }
        }
    )

    if $json {
        {layer: $n, title: $title, rows: $rows} | to json | print
    } else {
        print $title
        $rows
        | each {|row|
            $row | enumerate | reduce --fold {} {|it, acc| $acc | insert $"col($it.index + 1)" $"($it.item.keys)\n($it.item.action)" }
        }
        | print
    }
}

def main [] {
    print "usage: outlook-shortcuts.nu list [--list|--json] | layer <1-4> [--json] | set <category> <slot 1-16> [--force] | remove <category>"
}

# Show shortcuts. Default: 4x4 grid of VIA layer 2. --list: flat table. --json: all 16 slots, machine-readable.
def "main list" [--list (-l), --json (-j)] {
    let slots = (read-slots)
    let used = ($slots | where slot != null)
    let other = ($slots | where slot == null)

    if $json {
        1..16
        | each {|n|
            let p = (slot-pos $n)
            {
                slot: $n
                keys: $"⌃⌘F($n)"
                row: $p.row
                col: $p.col
                category: ($used | where slot == $n | get category | first | default null)
            }
        }
        | to json
        | print
        return
    }

    if $list {
        $used
        | sort-by slot
        | each {|r|
            let p = (slot-pos $r.slot)
            {
                category: $r.category
                keys: $"⌃⌘F($r.slot)"
                via_layer: $p.layer
                via_row: $p.row
                via_col: $p.col
            }
        }
        | print
    } else {
        1..4 | each {|row|
            1..4
            | reduce --fold {row: $"row($row)"} {|col, acc|
                let n = ($row - 1) * 4 + $col
                let cat = ($used | where slot == $n | get category | first | default "(free)")
                $acc | insert $"col($col)" $"⌃⌘F($n)\n($cat)"
            }
        }
        | print
        print $"VIA layer ($VIA_LAYER): key at row R, col C sends ⌃⌘F[4R-4+C]"
    }

    if ($other | is-not-empty) {
        print $"other bindings - not F-key, left untouched: ($other.category | str join ', ')"
    }
}

# Bind an Outlook category to ⌃⌘F<slot>.
def "main set" [
    category: string  # exact Outlook category name, e.g. 'BTS/Edu'
    slot: int         # 1-16 (VIA layer 2 key, row-major)
    --force (-f)      # replace a different category already on that slot
] {
    check-slot $slot
    let current = (read-raw)
    let slots = (read-slots)
    let clash = ($slots | where slot == $slot and category != $category)
    if ($clash | is-not-empty) and not $force {
        error make {msg: $"F($slot) already used by '($clash.category.0)'. Use --force to replace it."}
    }

    backup
    let value = $"($MODS)(fkey-char $slot)"
    let kept = (
        $current
        | where {|r| $r.category != $category and not ($clash | any {|c| $c.category == $r.category })}
    )
    write-all ($kept | append {category: $category, value: $value})
    let p = (slot-pos $slot)
    print $"'($category)' -> ⌃⌘F($slot)  [VIA layer ($p.layer), row ($p.row), col ($p.col)]"
    print "Restart Outlook to apply: killall 'Microsoft Outlook'"
}

# Remove the shortcut for a category.
def "main remove" [category: string] {
    let current = (read-raw)
    if not ($current | any {|r| $r.category == $category }) {
        error make {msg: $"no shortcut for '($category)'"}
    }
    backup
    write-all ($current | where category != $category)
    print $"removed '($category)'. Restart Outlook to apply: killall 'Microsoft Outlook'"
}
