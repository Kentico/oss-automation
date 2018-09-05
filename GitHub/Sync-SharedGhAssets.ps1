$repositoryPath = "C:\Users\janle\source\repos\"
$sourceRepo = "oss-automation"
$branchName = "dc-399-issue-templates"
$remoteBranchAlreadyExists = $true
$message = "Add/update issue, PR templates, code of conduct, contributing guide"
$description = "DC-399"
$excludedRepos = @("cloud-sdk-js", "delivery-sdk-net")
$risaRepos = `
    @("kentico-cloud-js", `
    "KenticoCloudSampleAngularApp", `
    "KenticoCloudSampleJavascriptApp", `
    "KenticoCloudModelGeneratorUtility", `
    "cloud-sample-app-js", `
    "KenticoCloudDeliveryNodeSDK")

cls
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$kenticoJsonFile = Invoke-RestMethod -Uri "https://api.github.com/orgs/kentico/repos?type=public" -Method Get
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

foreach ($row in $kenticoJsonFile)
{
    Sync-SharedGhAssets -RepoUrl $row.clone_url -RepoName $row.name
}
<#
foreach ($repo in $risaRepos)
{
    $risaJsonFile = Invoke-RestMethod -Uri ("https://api.github.com/repos/enngage/" + $repo) -Method Get
    Sync-SharedGhAssets -RepoUrl $risaJsonFile.clone_url -RepoName $risaJsonFile.name
}#>