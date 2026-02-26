# Find the directory ending with .git in the current directory
def "gt find-dir" [] {
    let git_dirs = (ls -a | where name ends-with ".git" | where type == "dir" | get name)
    # Check if there is exactly one .git directory
    if ($git_dirs | length) > 1 {
        error make {
            msg: "More than one .git directory found. Exiting."}
    }
    if ($git_dirs | length) == 0 {
        error make {msg: "No .git directory found. Exiting."}
    }
    # Return the found .git directory
    return ($git_dirs | get 0)
}

# Add a git worktree for the given branch
def "gt wt-add" [branch: string] {
    cd (gt find-dir)
    # Path for the new worktree, replacing '/' with '-' in the branch name
    let path = $"../($branch | str replace '/' '-')"
    print $"Adding worktree for existing branch '($branch)' at path '($path)'"
    git worktree add $path $branch
}

# Add a git worktree for the given branch
def "gt wt-new" [branch: string] {
    cd (gt find-dir)
    # Path for the new worktree, replacing '/' with '-' in the branch name
    let path = $"../($branch | str replace '/' '-')"
    print $"Adding worktree for new branch '($branch)' at path '($path)'"
    git worktree add -b $branch $path
    cd $path
}

# List all git branches in the current repository
def "gt branch" [] {
    cd (gt find-dir)
    git branch --all

}

# Show help for the gt command
def gt [] {
    help gt
}