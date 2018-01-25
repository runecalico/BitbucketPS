[CmdletBinding()]
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingWriteHost', '')]
param()

$DebugPreference = "SilentlyContinue"
$WarningPreference = "Continue"
if ($PSBoundParameters.ContainsKey('Verbose')) {
    $VerbosePreference = "Continue"
}

$releasePath = "$BuildRoot\Release"
$env:PSModulePath = "$($env:PSModulePath);$releasePath"

Install-Module BuildHelpers -Scope CurrentUser -AllowClobber
Import-Module BuildHelpers

# Ensure Invoke-Build works in the most strict mode.
Set-StrictMode -Version Latest

$branch = git branch 2>&1 | select-string -Pattern "^\*\s(.+)$" | Foreach-Object { $_.Matches.Groups[1].Value}
$commit = git log 2>&1 | select-string -Pattern "^commit ([0-9a-f]{7}) \(HEAD ->.*$branch.*$" | Foreach-Object { $_.Matches.Groups[1].Value}

$PROJECT_NAME = if ($env:APPVEYOR_PROJECT_NAME) {$env:APPVEYOR_PROJECT_NAME} elseif ($env:TRAVIS_REPO_SLUG) {$env:TRAVIS_REPO_SLUG} else {Split-Path $BuildRoot -Leaf}
$BUILD_FOLDER = if ($env:APPVEYOR_BUILD_FOLDER) {$env:APPVEYOR_BUILD_FOLDER} elseif ($env:TRAVIS_BUILD_DIR) {$env:TRAVIS_BUILD_DIR} else {$BuildRoot}
$REPO_NAME    = if ($env:APPVEYOR_REPO_NAME) {$env:APPVEYOR_REPO_NAME} elseif ($env:TRAVIS_REPO_SLUG) {$env:TRAVIS_REPO_SLUG} else {Split-Path $BuildRoot -Leaf}
$REPO_BRANCH = if ($env:APPVEYOR_REPO_BRANCH) {$env:APPVEYOR_REPO_BRANCH} elseif ($env:TRAVIS_BRANCH) {$env:TRAVIS_BRANCH} elseif ($branch) {$branch} else {''}
$REPO_COMMIT = if ($env:APPVEYOR_REPO_COMMIT) {$env:APPVEYOR_REPO_COMMIT} elseif ($env:TRAVIS_COMMIT) {$env:TRAVIS_COMMIT} elseif ($commit) {$commit} else {''}
$REPO_COMMIT_AUTHOR = if ($env:APPVEYOR_REPO_COMMIT_AUTHOR) {$env:APPVEYOR_REPO_COMMIT_AUTHOR} elseif ($env:TRAVIS_COMMIT) {''} else {''}

# region debug information
task ShowDebug {
    Write-Host -Foreground "Gray"
    switch ($true) {
        $env:APPVEYOR_JOB_ID { $CI = "AppVeyor"; continue }
        $env:TRAVIS { $CI = "Travis"; continue }
        Default { $CI = "local"; continue }
    }
    Write-Host $CI -Foreground "Gray"
    Write-Host -Foreground "Gray"
    Write-Host ('Project name:               {0}' -f $PROJECT_NAME) -Foreground "Gray"
    Write-Host ('Project root:               {0}' -f $BUILD_FOLDER) -Foreground "Gray"
    Write-Host ('Repo name:                  {0}' -f $REPO_NAME) -Foreground "Gray"
    Write-Host ('Branch:                     {0}' -f $REPO_BRANCH) -Foreground "Gray"
    Write-Host ('Commit:                     {0}' -f $REPO_COMMIT) -Foreground "Gray"
    Write-Host ('  - Author:                 {0}' -f $REPO_COMMIT_AUTHOR) -Foreground "Gray"

    Write-Host ('PowerShell version:         {0}' -f $PSVersionTable.PSVersion.ToString()) -Foreground "Gray"
    switch ($true) {
        $env:TRAVIS { $OS = $env:TRAVIS_OS_NAME; continue }
        Default { $OS = "Windows"; continue }
    }
    Write-Host ('OS:                         {0}' -f $OS) -Foreground "Gray"
    Write-Host ('OS Version:                 {0}' -f $PSVersionTable.BuildVersion.ToString()) -Foreground "Gray"


    if ($env:APPVEYOR_JOB_ID) {
        Write-Host ('Commit:                     {0}' -f $env:APPVEYOR_REPO_COMMIT) -Foreground "Gray"
        Write-Host ('  - Author:                 {0}' -f $env:APPVEYOR_REPO_COMMIT_AUTHOR) -Foreground "Gray"
        Write-Host ('  - Time:                   {0}' -f $env:APPVEYOR_REPO_COMMIT_TIMESTAMP) -Foreground "Gray"
        Write-Host ('  - Range:                  {0}' -f '') -Foreground "Gray"
        Write-Host ('  - Message:                {0}' -f $env:APPVEYOR_REPO_COMMIT_MESSAGE) -Foreground "Gray"
        Write-Host ('  - Extended message:       {0}' -f $env:APPVEYOR_REPO_COMMIT_MESSAGE_EXTENDED) -Foreground "Gray"
        Write-Host ('Pull request number:        {0}' -f $env:APPVEYOR_PULL_REQUEST_NUMBER) -Foreground "Gray"
        Write-Host ('Pull request title:         {0}' -f $env:APPVEYOR_PULL_REQUEST_TITLE) -Foreground "Gray"
        Write-Host ('Pull request SHA:           {0}' -f '') -Foreground "Gray"
        Write-Host ('AppVeyor build ID:          {0}' -f $env:APPVEYOR_BUILD_ID) -Foreground "Gray"
        Write-Host ('AppVeyor build number:      {0}' -f $env:APPVEYOR_BUILD_NUMBER) -Foreground "Gray"
        Write-Host ('AppVeyor build version:     {0}' -f $env:APPVEYOR_BUILD_VERSION) -Foreground "Gray"
        Write-Host ('AppVeyor job ID:            {0}' -f $env:APPVEYOR_JOB_ID) -Foreground "Gray"
        Write-Host ('Build triggered from tag?   {0}' -f $env:APPVEYOR_REPO_TAG) -Foreground "Gray"
        Write-Host ('  - Tag name:               {0}' -f $env:APPVEYOR_REPO_TAG_NAME) -Foreground "Gray"
        Write-Host ('PowerShell version:         {0}' -f $PSVersionTable.PSVersion.ToString()) -Foreground "Gray"
        Write-Host ('OS:                         {0}' -f 'Windows') -Foreground "Gray"
        Write-Host ('OS Version:                 {0}' -f $PSVersionTable.BuildVersion.ToString()) -Foreground "Gray"
    } elseif ($env:TRAVIS) {
        Write-Host "Using Travis-CI" -Foreground "Gray"
        Write-Host -Foreground "Gray"
        Write-Host ('Project name:               {0}' -f $env:TRAVIS_REPO_SLUG) -Foreground "Gray"
        Write-Host ('Project root:               {0}' -f $env:TRAVIS_BUILD_DIR) -Foreground "Gray"
        Write-Host ('Repo name:                  {0}' -f $env:TRAVIS_REPO_SLUG) -Foreground "Gray"
        Write-Host ('Branch:                     {0}' -f $env:TRAVIS_BRANCH) -Foreground "Gray"
        Write-Host ('Commit:                     {0}' -f $env:TRAVIS_COMMIT) -Foreground "Gray"
        Write-Host ('  - Author:                 {0}' -f '') -Foreground "Gray"
        Write-Host ('  - Time:                   {0}' -f '') -Foreground "Gray"
        Write-Host ('  - Range:                  {0}' -f $env:TRAVIS_COMMIT_RANGE) -Foreground "Gray"
        Write-Host ('  - Message:                {0}' -f $env:TRAVIS_COMMIT_MESSAGE) -Foreground "Gray"
        Write-Host ('  - Extended message:       {0}' -f '') -Foreground "Gray"
        Write-Host ('Pull request number:        {0}' -f $env:TRAVIS_PULL_REQUEST) -Foreground "Gray"
        Write-Host ('Pull request title:         {0}' -f '') -Foreground "Gray"
        Write-Host ('Pull request SHA:           {0}' -f $env:TRAVIS_PULL_REQUEST_SHA) -Foreground "Gray"
        Write-Host ('AppVeyor build ID:          {0}' -f $env:TRAVIS_BUILD_ID) -Foreground "Gray"
        Write-Host ('AppVeyor build number:      {0}' -f $env:TRAVIS_BUILD_NUMBER) -Foreground "Gray"
        Write-Host ('AppVeyor build version:     {0}' -f $env:TRAVIS_BUILD_NUMBER) -Foreground "Gray"
        Write-Host ('AppVeyor job ID:            {0}' -f $env:TRAVIS_JOB_ID) -Foreground "Gray"
        Write-Host ('Build triggered from tag?   {0}' -f ([bool]$env:TRAVIS_TAG)) -Foreground "Gray"
        Write-Host ('  - Tag name:               {0}' -f $env:TRAVIS_TAG) -Foreground "Gray"
        Write-Host ('PowerShell version:         {0}' -f $PSVersionTable.PSVersion.ToString()) -Foreground "Gray"
        Write-Host ('OS:                         {0}' -f $env:TRAVIS_OS_NAME) -Foreground "Gray"
        Write-Host ('OS Version:                 {0}' -f $PSVersionTable.BuildVersion.ToString()) -Foreground "Gray"
    } else {
        Write-Host "Using local build" -Foreground "Gray"
        Write-Host -Foreground "Gray"
        Write-Host ('PowerShell version:         {0}' -f $PSVersionTable.PSVersion.ToString()) -Foreground "Gray"
        Write-Host ('OS:                         {0}' -f '') -Foreground "Gray"
        Write-Host ('OS Version:                 {0}' -f $PSVersionTable.BuildVersion.ToString()) -Foreground "Gray"
    }
    Write-Host -Foreground "Gray"
}
exit
# Synopsis: Install pandoc to .\Tools\
task InstallPandoc -If (-not (Test-Path Tools\pandoc.exe)) {
    # Setup
    if (-not (Test-Path "$BuildRoot\Tools")) {
        $null = New-Item -Path "$BuildRoot\Tools" -ItemType Directory
    }

    # Get latest bits
    $latestRelease = "https://github.com/jgm/pandoc/releases/download/2.1/pandoc-2.1-windows.zip"
    Invoke-WebRequest -Uri $latestRelease -OutFile "$($env:temp)\pandoc.msi"

    # Extract bits
    $null = New-Item -Path $env:temp\pandoc -ItemType Directory -Force
    Start-Process -Wait -FilePath msiexec.exe -ArgumentList " /qn /a `"$($env:temp)\pandoc.msi`" targetdir=`"$($env:temp)\pandoc\`""

    # Move to Tools folder
    Copy-Item -Path "$($env:temp)\pandoc\Pandoc\pandoc.exe" -Destination "$BuildRoot\Tools\"
    Copy-Item -Path "$($env:temp)\pandoc\Pandoc\pandoc-citeproc.exe" -Destination "$BuildRoot\Tools\"

    # Clean
    Remove-Item -Path "$($env:temp)\pandoc" -Recurse -Force
}
# endregion

# region test
task Test {
    assert { Test-Path "Release/" -PathType Container }

    try {
        $result = Invoke-Pester -PassThru -OutputFile "$BuildRoot\TestResult.xml" -OutputFormat "NUnitXml"
        if ($env:APPVEYOR_PROJECT_NAME) {
            Add-TestResultToAppveyor -TestFile "$BuildRoot\TestResult.xml"
            Remove-Item "$BuildRoot\TestResult.xml" -Force
        }
        assert ($result.FailedCount -eq 0) "$($result.FailedCount) Pester test(s) failed."
    }
    catch {
        throw
    }
}
# endregion

# region build
# Synopsis: Build shippable release
task Build GenerateRelease, ConvertMarkdown, UpdateManifest

task CreateHelp {
    Install-Module platyPS -Scope CurrentUser
    Import-Module platyPS -Force
    New-ExternalHelp -Path "$BuildRoot\docs\commands" -OutputPath "$BuildRoot\BitbucketPS\en-US" -Force
    Remove-Module BitbucketPS, platyPS
}

# Synopsis: Generate .\Release structure
task GenerateRelease CreateHelp, {
    # Setup
    if (-not (Test-Path "$releasePath\BitbucketPS")) {
        $null = New-Item -Path "$releasePath\BitbucketPS" -ItemType Directory
    }

    # Copy module
    Copy-Item -Path "$BuildRoot\BitbucketPS\*" -Destination "$releasePath\BitbucketPS" -Recurse -Force
    # Copy additional files
    $additionalFiles = @(
        "$BuildRoot\CHANGELOG.md"
        "$BuildRoot\LICENSE"
        "$BuildRoot\README.md"
    )
    Copy-Item -Path $additionalFiles -Destination "$releasePath\BitbucketPS" -Force
}

# Synopsis: Update the manifest of the module
task UpdateManifest GetVersion, {
    Update-Metadata -Path "$releasePath\BitbucketPS\BitbucketPS.psd1" -PropertyName ModuleVersion -Value $script:Version
    # Update-Metadata -Path "$releasePath\BitbucketPS\BitbucketPS.psd1" -PropertyName FileList -Value (Get-ChildItem $releasePath\BitbucketPS -Recurse).Name
    $functionsToExport = Get-ChildItem "$BuildRoot\BitbucketPS\Public" | ForEach-Object {$_.BaseName}
    Set-ModuleFunctions -Name "$releasePath\BitbucketPS\BitbucketPS.psd1" -FunctionsToExport $functionsToExport
}

task GetVersion {
    $manifestContent = Get-Content -Path "$releasePath\BitbucketPS\BitbucketPS.psd1" -Raw
    if ($manifestContent -notmatch '(?<=ModuleVersion\s+=\s+'')(?<ModuleVersion>.*)(?='')') {
        throw "Module version was not found in manifest file,"
    }

    $currentVersion = [Version] $Matches.ModuleVersion
    if ($env:APPVEYOR_BUILD_NUMBER) {
        $newRevision = $env:APPVEYOR_BUILD_NUMBER
    }
    else {
        $newRevision = 0
    }
    $script:Version = New-Object -TypeName System.Version -ArgumentList $currentVersion.Major,
    $currentVersion.Minor,
    $newRevision
}

# Synopsis: Convert markdown files to HTML.
# <http://johnmacfarlane.net/pandoc/>
$ConvertMarkdown = @{
    Inputs  = { Get-ChildItem "$releasePath\BitbucketPS\*.md" -Recurse }
    Outputs = {process {
            [System.IO.Path]::ChangeExtension($_, 'htm')
        }
    }
}
# Synopsis: Converts *.md and *.markdown files to *.htm
task ConvertMarkdown -Partial @ConvertMarkdown InstallPandoc, {process {
        exec { Tools\pandoc.exe $_ --standalone --from=markdown_github "--output=$2" }
    }
}, RemoveMarkdownFiles
# endregion

# region publish
function GetBuild() {
    $headers = @{
      "Authorization" = "Bearer $env:ApiKey"
      "Content-type" = "application/json"
    }
    Invoke-RestMethod -Uri "https://ci.appveyor.com/api/projects/$env:APPVEYOR_ACCOUNT_NAME/$env:APPVEYOR_PROJECT_SLUG" -Headers $headers -Method GET
}
function allJobsFinished() {
    $buildData = GetBuild
    $lastJob = ($buildData.build.jobs | Select -Last 1).jobId

    if ($lastJob -ne $env:APPVEYOR_JOB_ID) {
        return $false
    }

    write-host "Waiting for other jobs to complete"

    [datetime]$stop = ([datetime]::Now).AddMinutes($env:TimeOutMins)
    [bool]$success = $false

    while(!$success -and ([datetime]::Now) -lt $stop) {
        $project = GetBuild
        $success = $true
        $project.build.jobs | foreach-object {if (($_.jobId -ne $env:APPVEYOR_JOB_ID) -and ($_.status -ne "success")) {$success = $false}; $_.jobId; $_.status}
        if (!$success) {Start-sleep 5}
    }

    if (!$success) {throw "Test jobs were not finished in $env:TimeOutMins minutes"}
}
function allCIsFinished() {
    #region Travis
    # install https://github.com/travis-ci/travis.rb#installation
    # get API token according https://developer.travis-ci.com/authentication

    # $env:TRAVIS_API_TOKEN = "<replace>" # must be secure variable set in Environment tab or YAML section
    # $env:TimeOutMins = <replace> # how long to wait for Travis build to complete (set in Environment tab or YAML section)

    # $headers = @{
    #   "Authorization" = "token $env:TRAVIS_API_TOKEN"
    #   "Travis-API-Version" = "3"
    # }

    # [datetime]$stop = ([datetime]::Now).AddMinutes($env:TimeOutMins)
    # [bool]$success = $false

    # while(!$success -and ([datetime]::Now) -lt $stop) {
    #     $builds = Invoke-RestMethod -Uri "https://api.travis-ci.org/builds?limit=10" -Headers $headers  -Method Get
    #     $currentBuild = $builds.builds | ? {$_.commit.sha -eq $env:APPVEYOR_REPO_COMMIT}
    #     $success = $currentBuild.state -eq "passed"
    #     if (!$success) {Start-sleep 5}
    # }
    # if (!$currentBuild) {throw "Could not get information about Travis build with sha $env:APPVEYOR_REPO_COMMIT"}
    # if (!$success) {throw "Travis build did not finished in $env:TimeOutMins minutes"}
    #endregion Travis
}
# Do not deploy if this is a pull request (because it hasn't been approved yet)
# Do not deploy if the commit contains the string "skip-deploy"
# Meant for major/minor version publishes with a .0 build/patch version (like 2.1.0)
$shouldDeploy = `
    # only deploy from AppVeyor
    $CI -eq "AppVeyor" -and
    # only deploy from last Job
    (allJobsFinished) -and
    # Travis must have passed as well
    (allCIsFinished)
    # only deploy master branch
    $env:APPVEYOR_REPO_BRANCH -eq 'master' -and
    # it cannot be a PR
    (-not ($env:APPVEYOR_PULL_REQUEST_NUMBER)) -and
    # it cannot have a commit message that contains "skip-deploy"
    $env:APPVEYOR_REPO_COMMIT_MESSAGE -notlike '*skip-deploy*'
task Deploy -If $shouldDeploy PublishToGallery, UpdateHomepage

task PublishToGallery {
    assert ($env:PSGalleryAPIKey) "No key for the PSGallery"

    Remove-Module BitbucketPS -ErrorAction SilentlyContinue
    Import-Module $releasePath\BitbucketPS\BitbucketPS.psd1 -ErrorAction Stop
    Publish-Module -Name BitbucketPS -NuGetApiKey $env:PSGalleryAPIKey
}

task UpdateHomepage {
    try {
        # Get the repo of the homepage
        exec { git clone https://github.com/AtlassianPS/AtlassianPS.github.io --recursive } -ErrorAction SilentlyContinue
        Write-Host "Cloned"
        Set-Location "AtlassianPS.github.io/"

        # Update all submodules
        exec { git submodule foreach git pull origin master } -ErrorAction SilentlyContinue
        Write-Host "Fetched"

        # Check if this repo was changed
        $status = exec { git status -s }
        if ($status -contains " M modules/BitbucketPS") {
            Write-Host "Has changes"
            # Update the repo in the homepage repo
            exec { git add modules/BitbucketPS }
            Write-Host "Added"
            exec { git commit -m "Update module BitbucketPS" } -ErrorAction SilentlyContinue
            Write-Host "Commited"
            exec { git push }
            Write-Host "Pushed"
        }
    }
    catch {
        throw "Failed to updated the website"
    }
}
# endregion

#region Cleaning tasks
task Clean RemoveGeneratedFiles

# Synopsis: Remove generated and temp files.
task RemoveGeneratedFiles {
    $itemsToRemove = @(
        'Release'
        '*.htm'
        'TestResult.xml'
        'BitbucketPS\en-US\*'
    )
    Remove-Item $itemsToRemove -Force -Recurse -ErrorAction 0
}

task RemoveMarkdownFiles {
    Remove-Item "$releasePath\BitbucketPS\*.md" -Force -ErrorAction 0
}
# endregion

task . ShowDebug, Clean, Build, Test, Deploy
