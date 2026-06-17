# Publish code changes to GitHub after release artifacts are created.
# This script does not upload ZIP release assets; those should be attached to a GitHub Release manually.

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $repoRoot

$remoteUrl = git config --get remote.origin.url
if (-not $remoteUrl) {
    Write-Host "ERROR: No git remote configured for origin." -ForegroundColor Red
    Write-Host "Add your GitHub remote with something like:" -ForegroundColor Yellow
    Write-Host "  git remote add origin https://github.com/<username>/<repo>.git"
    exit 1
}

Write-Host "Using remote origin: $remoteUrl" -ForegroundColor Green
Write-Host "Current branch: $(git branch --show-current)" -ForegroundColor Green

Write-Host "Checking status..." -ForegroundColor Cyan
git status --short

Write-Host "Adding all code changes (skipping ignored release artifacts)..." -ForegroundColor Cyan
git add .

Write-Host "Committing changes..." -ForegroundColor Cyan
git commit -m "Prepare release: update source code" -q

Write-Host "Pushing to origin..." -ForegroundColor Cyan
git push origin HEAD

Write-Host "Done. Code pushed to GitHub." -ForegroundColor Green
