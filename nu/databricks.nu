# Config for Databricks workspace and cluster
let DEFAULT_DATABRICKS_WORKSPACE = "dnacommondbwsp02n1d02"
let DEFAULT_DATABRICKS_CLUSTER_ID = "1020-071410-fiqjxuwk"

# Config and cache files stored in project root directory
let DATABRICKS_CONFIG_FILE = "databricks.config.json"
let DATABRICKS_CACHE_FILE = "databricks.cached.json"

# Start the databricks cluster.
def "dbx hi" [] {
    databricks --profile $DEFAULT_DATABRICKS_WORKSPACE clusters start $DEFAULT_DATABRICKS_CLUSTER_ID
}

# Get the databricks profile from the databricks config file
def "dbx profile" [] {
    return (open $DATABRICKS_CONFIG_FILE | get profile)
}

# Get the databricks repo path from the databricks config file
def "dbx repo-path" [] {
    return (open $DATABRICKS_CONFIG_FILE | get repo-path)
}

# Get the git remote name from the databricks config file
def "dbx remote" [] {
    return (open $DATABRICKS_CONFIG_FILE | get remote)
}

# Get the databricks repo id from the databricks config file or from Databricks
def "dbx repo-id" [] {
    # try to read the repo id from the cache file
    let repo_id = try {
        open $DATABRICKS_CACHE_FILE | get repo_id
    } catch {
        # if the cache file does not exist, get the repo id from databricks
        let profile =  dbx profile
        let repo_path = dbx repo-path

        print ($"Getting repo id from databricks for profile: ($profile) and repo path: ($repo_path)")
        let repo_id = databricks --profile $profile repos get $repo_path | from json | get id  

        # Cache for future use
        {"repo_id": $repo_id} | to json | save -f $DATABRICKS_CACHE_FILE
        $repo_id
    }
    return $repo_id
}

# Update the databricks repo with the latest changes from the remote repo
def "dbx repo-update" [] {
    let profile =  dbx profile
    let repo_id = dbx repo-id
    let branch = git symbolic-ref --short HEAD
    print "------------------------"
    print "Databricks: Update repo"
    print ($"-- profile: ($profile)")
    print ($"-- repo id: ($repo_id)")
    print ($"-- branch: ($branch)")
    print "------------------------"
    databricks --profile $profile repos update $repo_id --branch $branch
}

# Commit and push changes to the remote repo, then update the databricks repo
def "dbx push" [
    commit_message: string # The commit message
] {
    let profile =  dbx profile
    let repo_id = dbx repo-id
    let branch = git symbolic-ref --short HEAD
    let remote = dbx remote
    print "--------"
    print "Git: Add"
    print "--------"
    git add . --verbose
    print "-----------"
    print "Git: Commit"
    print "-----------"
    git commit -m $"($commit_message)"
    print "---------"
    print "Git: Push"
    print "---------"
    git push $remote $branch
    dbx repo-update
}

def dbx [] {
    print "dbx needs a subcommand. Type 'help dbx' for more details."
}

## Aliases
alias hi = dbx hi
alias pu = dbx push