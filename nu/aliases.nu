# Tibor's Aliases

alias ? = echo "?a=aliases, ?c=commands, ?e=$env, ?s=engine-stats, ?x=externs, ?m=modules, ?v=variables"
alias ?a = scope aliases
alias ?c = scope commands 
alias ?e = echo $env
alias ?s = scope engine-stats
alias ?x = scope externs
alias ?m = scope modules
alias ?v = scope variables

alias cat = ccat

## Print config paths
alias nuc = echo $nu.config-path
alias nue = echo $nu.env-path

## Navigate to local folders
### -- pybrickz
alias pb = cd ~/Projects/pybrickz
### -- rbrickz
alias prbr = cd ~/Projects/rbrickz

## Open links in browser
### -- ADO/dna-packages/pybrickz
alias apbr = start https://dev.azure.com/zna-predictive-analytics/dna-packages/_git/pybrickz
### -- ADO/dna-packages/rbrickz
alias arbr = start https://dev.azure.com/zna-predictive-analytics/dna-packages/_git/rbrickz
### -- Jira/DAM
alias jdam = start https://jira.zurichna.com/browse/DAM/
### -- Jira/DMR
alias jdmr = start https://jira.zurichna.com/browse/DMR/
### -- Jira/DAE
alias jdae = start https://jira-zurichna.atlassian.net/jira/software/c/projects/DAE/boards/11/
### -- Jira/DAR
alias jdar = start https://jira-zurichna.atlassian.net/jira/software/c/projects/DAR/boards/9/
### -- Jira/DP
alias jdp = start https://jira-zurichna.atlassian.net/jira/software/c/projects/DP/boards/22/
### -- Databricks/dnadbwspcommon01
alias ddnacom = start http://adb-744809576436235.15.azuredatabricks.net/
### -- Databricks/anadbfinactd01
alias dfinact = start http://adb-744809576436235.15.azuredatabricks.net/
### -- Databricks/anadbwsp01cloudlakepa01
alias dclpa01 = start https://adb-8703774962922820.0.azuredatabricks.net/
### -- Databricks/anadbwsp12cloudlakeqa01
alias dclqa01 = start https://adb-4321108820673507.7.azuredatabricks.net/
### -- Databricks/anadbwsppa01
alias dpa01 = start https://adb-1854015508783085.5.azuredatabricks.net/
### -- Databricks/
alias ddev02 = start https://adb-2405775634121026.6.azuredatabricks.net/
### -- Databricks/qa
alias dqa02 = start https://adb-246050047085946.6.azuredatabricks.net/
### -- Databricks/prod
alias dprod02 = start https://adb-6461475676310004.4.azuredatabricks.net/
### -- Dataiku/cloud01
alias cloud01 = start https://dataikucloud01.zurich.com/
### -- Dataiku/automation01
alias automation01 = start https://dataikuautomation01.zurich.com/

## Git shortcuts
alias ga = git add
alias gb = git branch --all
alias gc = git commit
alias gf = git pull
alias gm = git merge
alias gp = git push
# alias gs = git status
alias gx = git checkout

def sync [commit_message="auto sync"] {
    git pull
    git add . 
    git commit -m $commit_message
    git push
}

## Python virtualenv
alias venv = overlay use .venv\Scripts\activate.nu
alias d = deactivate

alias rf = uv run ruff check --fix

alias tf = terraform

def admire [] {
    cd C:\Users\TIBOR.STANKO\Projects\admire
    uv run admire
}

alias adm = admire