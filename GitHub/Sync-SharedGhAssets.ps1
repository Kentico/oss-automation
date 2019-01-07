$repositoryPath = "C:\Users\<username>\source\repos\"
$sourceRepo = "oss-automation"
$branchName = "dc-399-shared-assets"
$remoteBranchAlreadyExists = $true
$message = "Add/update issue, PR templates, code of conduct, contributing guide"
$description = "DC-399"
$pages = 3
$excludedRepos = @("cloud-sdk-js")
$externalRepos = `
    @("Enngage/KenticoCloudSampleAngularApp", `
    "Enngage/KenticoCloudSampleJavascriptApp")

cls
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$excludedRepos += $sourceRepo
$sourcePath = $repositoryPath + $sourceRepo + "\GitHub\Root"
$templatePath = $sourcePath + "\.github"

function Sync-SharedGhAssets
{
    Param (`
        [string] $RepoUrl, `
        [string] $RepoName)

    $fullPath = $repositoryPath + $RepoName

    if ($excludedRepos -notcontains $RepoName)
    {
        if (Test-Path -Path $fullPath)
        {
            cd $fullPath
            git fetch --all
            git checkout master
            git pull
        }
        else
        {
            git clone $RepoUrl $fullPath
        }

        cd $fullPath

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
            md .github
        }
        
        robocopy $sourcePath $fullPath CODE_OF_CONDUCT.md
        robocopy $sourcePath $fullPath CONTRIBUTING.md
        robocopy $templatePath ($fullPath + "\.github") * /s
        Start-Sleep -Seconds 2
        git add .\CODE_OF_CONDUCT.md -f
        git add .\CONTRIBUTING.md -f
        $files = Get-ChildItem -Path ($fullPath + "\.github") -Recurse
 
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
        
        git request-pull master .\
        hub pull-request -m "$message" --no-edit
    }

}

if (-Not (Test-Path -Path $sourcePath))
{
    git clone ("https://github.com/Kentico/" + $sourceRepo + ".git") $repositoryPath
}

for ($x = 1; $x -le $pages; $x++)
{
    $kenticoJsonFile = Invoke-RestMethod -Uri ("https://api.github.com/orgs/kentico/repos?type=public&page=" + $x) -Method Get

    foreach ($row in $kenticoJsonFile)
    {
        Sync-SharedGhAssets -RepoUrl $row.clone_url -RepoName $row.name
    }
}

foreach ($repo in $externalRepos)
{
    $externalJsonFile = Invoke-RestMethod -Uri ("https://api.github.com/repos/" + $repo) -Method Get
    Sync-SharedGhAssets -RepoUrl $externalJsonFile.clone_url -RepoName $externalJsonFile.name
}
