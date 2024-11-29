
echo "When prompted, enter your github username and instead of your password, enter your Personal Access Token"

paket config add-credentials https://nuget.pkg.github.com/marquette-ea/index.json --authtype basic --verify

gh auth login
gh auth setup-git

az login

