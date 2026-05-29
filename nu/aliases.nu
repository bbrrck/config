# Tibor's Aliases
source _paths.nu

alias ? = echo "?a=aliases, ?c=commands, ?e=$env, ?s=engine-stats, ?x=externs, ?m=modules, ?v=variables"
alias ?a = scope aliases
alias ?c = scope commands
alias ?e = echo $env
alias ?s = scope engine-stats
alias ?x = scope externs
alias ?m = scope modules
alias ?v = scope variables

let os_name = ($nu.os-info | get name);
match $os_name {
    "windows" => {
        alias cat = ccat
    }
}

## Print config paths
alias nuc = echo $nu.config-path
alias nue = echo $nu.env-path

## Git shortcuts
alias ga = git add
alias gb = git branch --all
alias gc = git commit
alias gf = git pull
alias gm = git merge
alias gp = git push
alias gx = git checkout

## Python virtualenv
alias venv = overlay use .venv\Scripts\activate.nu
alias d = deactivate

## Common commands
def codechecks [] {
    print "=== RUNNING CODE CHECKS ==="
    print "--- RUFF FORMAT ---"
    uv run ruff format
    print "--- RUFF CHECK ---"
    uv run ruff check --fix
    print "--- TY CHECK ---"
    uv run ty check
    print "=== CODE CHECKS COMPLETED ==="
}

alias rf = uv run ruff format
alias rc = uv run ruff check
alias pf = uv run pyrefly check
alias tc = uv run ty check
alias tf = terraform
alias ch = codechecks
alias cc = claude

def admire [] {
    cd $PATH_ADMIRE
    uv run admire
}

alias adm = admire

def par [] {
    cd $PATH_ADMIRE
    uv run par
}

def reload [] {
    exec nu
}

alias j = just

alias dbxdv = databricks -p dnacommondbwsp02n1d02
alias dbxqa = databricks -p dnacommondbwsp02n1q02
alias dbxpr = databricks -p dnacommondbwsp02p1p02

alias p = cd $PATH_PROJECTS
alias pb = cd $PATH_PYBRICKZ
