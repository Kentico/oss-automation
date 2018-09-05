$repositoryPath = "C:\Users\janl\source\repos\"
$sourceRepo = "oss-automation"
$branchName = "dc-399-issue-templates"
$remoteBranchAlreadyExists = $true
$description = "DC-399"
$excludedRepos = @("Home", "cloud-sdk-js", "delivery-sdk-net", "KInspector")

cls
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$jsonFile = Invoke-RestMethod -Uri "https://api.github.com/orgs/kentico/repos?type=public" -Method Get
$excludedRepos += $sourceRepo
$sourcePath = $repositoryPath + $sourceRepo
$templatePath = $sourcePath + "\.github"

if (!Test-Path -Path $sourcePath)
{
    git clone ("https://github.com/Kentico/" + $sourceRepo + ".git") $repositoryPath
}

foreach ($row in $jsonFile)
{
    $gitUrl = $row.clone_url
    $name = $row.name
    $fullPath = $repositoryPath + $name

    if ($excludedRepos -notcontains $name)
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
            git clone $gitUrl $fullPath
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
        <#cd ($fullPath + "\.github")
        $files = Get-ChildItem $fileMask
        cd ..

        foreach ($file in $files)
        {
            git add $file.FullName
        }#>

        git commit -a -m "Add/update issue, PR templates, code of conduct, contributing guide" -m $description
        
        if (!$remoteBranchAlreadyExists)
        {
            git push --set-upstream origin $branchName
        }
        else
        {
            git push
        }
        
        git request-pull master .\
        hub pull-request --no-edit
    }
}