$repositoryPath = "C:\Users\janl\source\repos\"
$templatePath = "C:\Users\janl\source\repos\.github"
$fileMask = "pull*"
$branchName = "dc-399-issue-templates"
$remoteBranchAlreadyExists = $true
$description = "DC-399"
$excludedRepos = @("Home", "cloud-sdk-js", "delivery-sdk-net", "KInspector")

cls
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$jsonFile = Invoke-RestMethod -Uri "https://api.github.com/orgs/kentico/repos?type=public" -Method Get

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
        
        robocopy $templatePath ($fullPath + "\.github") $fileMask /s
        cd ($fullPath + "\.github")
        $files = Get-ChildItem $fileMask
        cd ..

        foreach ($file in $files)
        {
            git add $file.FullName
        }

        git commit -a -m "Add/update issue/PR templates" -m $description
        
        if (!$remoteBranchAlreadyExists)
        {
            git push --set-upstream origin $branchName
        }
        else
        {
            git push
        }
        
        #git request-pull origin/master ("origin/" + $branchName)
    }
}