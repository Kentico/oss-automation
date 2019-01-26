$repositoryPath = "C:\Users\<username>\<...>"
$sourceRepo = "oss-automation"
$branchName = "master"
$remoteBranchAlreadyExists = $true
$message = "Add/update issue, PR templates, code of conduct, contributing guide"
$description = "DCN-34 - adjusted expectations"
$pages = 3
$excludedRepos = @("xyz")
$externalRepos = `
    @("Enngage/KenticoCloudSampleAngularApp", `
    "Enngage/KenticoCloudSampleJavascriptApp")

Clear-Host
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$excludedRepos += $sourceRepo
$sourcePath = Join-Path (Join-Path $repositoryPath $sourceRepo) "\GitHub\Root"


function Sync-SharedGhAssets
{
    Param (`
        [string] $RepoUrl, `
        [string] $RepoName)
        
    Write-Output ("Cloning: " + $RepoName)

    $fullPath = Join-Path $repositoryPath $RepoName

    if ($excludedRepos -notcontains $RepoName)
    {
        if (Test-Path -Path $fullPath)
        {
            Set-Location $fullPath
            git fetch --all
            git checkout master
            git pull
        }
        else
        {
            git clone $RepoUrl $fullPath
        }

        Set-Location $fullPath

        if (!$remoteBranchAlreadyExists)
        {
            git branch -d $branchName
            git push origin (":" + $branchName)
            git branch $branchName
        }

        git checkout $branchName
        git pull

        if (!$remoteBranchAlreadyExists)
        {
            mkdir .github
        }
        
        robocopy $sourcePath $fullPath CODE_OF_CONDUCT.md
        robocopy $sourcePath $fullPath CONTRIBUTING.md
        $sourceTemplatePath = Join-Path $sourcePath "\.github"
        $destTemplatePath = Join-Path $fullPath "\.github"
        robocopy $sourceTemplatePath $destTemplatePath * /s
        Start-Sleep -Seconds 2
        git add .\CODE_OF_CONDUCT.md -f
        git add .\CONTRIBUTING.md -f
        $files = Get-ChildItem -Path (Join-Path $fullPath "\.github") -Recurse
 
        foreach ($file in $files) 
        { 
            git add $file.FullName -f
        } 

        git commit -a -m $message -m $description
        
        if (!$remoteBranchAlreadyExists)
        {
            git push --set-upstream origin $branchName
        }
        else
        {
            git push
        }
        
        if($branchName -ne "master")
        {
            # Submit a pull request if not pushing directly to master
            git request-pull master .\
            hub pull-request -m "$message" --no-edit
        }
    }

}

if (-Not (Test-Path -Path $sourcePath))
{
    git clone ("https://github.com/Kentico/" + $sourceRepo + ".git") (Join-Path $repositoryPath $sourceRepo)
}

for ($x = 1; $x -le $pages; $x++)
{
    $kenticoJsonFile = Invoke-RestMethod -Uri ("https://api.github.com/orgs/kentico/repos?type=public&page=" + $x) -Method Get

    foreach ($row in $kenticoJsonFile)
    {
        # Skip archived repos (can't be modified)
        if($row.archived -eq $false)
        {
            Sync-SharedGhAssets -RepoUrl $row.clone_url -RepoName $row.name
        }
    }
}

foreach ($repo in $externalRepos)
{
    $externalJsonFile = Invoke-RestMethod -Uri ("https://api.github.com/repos/" + $repo) -Method Get
    Sync-SharedGhAssets -RepoUrl $externalJsonFile.clone_url -RepoName $externalJsonFile.name
}
