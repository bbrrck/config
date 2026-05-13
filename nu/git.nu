# Git Worktree shortcuts

def "gw ls" [] {
    print "-------------"
    print "Git branches:"
    print "-------------"
    git branch --all
    print ""
    print "--------------"
    print "Git worktrees:"
    print "--------------"
    git worktree list
}

def "gw add" [branch: string, from: string = "main"] {
    let path = $branch
    print $"Adding worktree for existing branch '($branch)' at path '($path)'"
    git worktree add -b $branch $branch $from
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