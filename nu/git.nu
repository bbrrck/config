# Git Worktree shortcuts

def "gw ls" [] {
    let cwd = $env.PWD
    ^git worktree list --porcelain
    | split row "\n\n"
    | where {|r| $r | str trim | is-not-empty }
    | each {|r|
        let f = $r | lines | parse "{key} {value}" | transpose -r -d
        let p = $f.worktree
        {
            path: (if $p == $cwd { "." } else if ($p | str starts-with $"($cwd)/") { $p | path relative-to $cwd } else { $p })
            head: ($f.HEAD | str substring 0..7)
            branch: ($f.branch? | default "(detached)" | str replace "refs/heads/" "")
        }
    }
}

def --env "gw add" [branch: string, from: string = "main"] {
    let path = $branch
    print $"Adding worktree for existing branch '($branch)' at path '($path)'"
    git worktree add -b $branch $branch $from
    cd $path
    git status
}

def "gw rm" [branch: string, --force] {
    print $"Removing worktree for branch '($branch)' [force: ($force)]"
    git worktree remove $branch --force
    print $"Removing branch '($branch)'"
    if $force {
        git branch -D $branch
    } else {
        git branch -d $branch
    }
}

def gw [] {
    help gw
}

alias gwl = gw ls
alias gwa = gw add
alias gwr = gw rm
