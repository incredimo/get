# ██  ██████      ████  ██████    ██████  ██████    ██  ████████    ██████
# ██  ██    ██  ██      ██    ██  ██      ██    ██  ██  ██  ██  ██  ██    ██
# ██  ██    ██  ██      ██████    ████    ██    ██  ██  ██  ██  ██  ██    ██
# ██  ██    ██  ██████  ██    ██  ██████  ██████    ██  ██  ██  ██    ██████

# Remove all generic PowerShell messages
$PSDefaultParameterValues['*:NoLogo'] = $true
$PSDefaultParameterValues['*:NoProfile'] = $true
$PSDefaultParameterValues['*:NoBanner'] = $true
$PSDefaultParameterValues['*:NoExit'] = $true
$PSDefaultParameterValues['*:NoPrompt'] = $true

# Clear previous line to remove the default prompt
Write-Host "`e[1A`e[0K"

# Define color codes for direct use in the prompt gradient VIBGYOR
$colors = @{
    "violet_dark"  = "148;0;211"
    "violet"       = "180;0;255"
    "indigo_dark"  = "75;0;130"
    "indigo"       = "54;0;170"
    "blue_dark"    = "0;0;139"
    "blue"         = "0;0;255"
    "cyan_dark"    = "0;139;139"
    "cyan"         = "0;255;255"
    "green_dark"   = "0;100;0"
    "green"        = "0;255;0"
    "yellow_dark"  = "154;205;50"
    "yellow"       = "255;255;0"
    "orange_dark"  = "255;140;0"
    "orange"       = "255;165;0"
    "red_dark"     = "139;0;0"
    "red"          = "255;0;0"
    "pink_dark"    = "219;112;147"
    "pink"         = "255;105;180"
    "purple_dark"  = "128;0;128"
    "purple"       = "186;85;211"
    "grey_dark"    = "105;105;105"
    "grey"         = "128;128;128"
    "brown_dark"   = "139;69;19"
    "brown"        = "165;42;42"
    "white_dark"   = "211;211;211"
    "white"        = "255;255;255"
    "reset"        = "0"
    "black"        = "0;0;0"
    "magenta_dark" = "139;0;139"
    "magenta"      = "255;0;255"
    "brightBlack"  = "80;80;80"
    "cyan_bright"  = "0;255;255"
    "pink_bright"  = "255;20;147"
}

$reset_color = "`e[0m"
$gray = "`e[38;5;240m"

function fmt {
    param(
        [string]$text,
        [string]$foreground,
        [string]$background
    )
    # If no background color is provided, only use foreground color
    if (!$background) {
        return "`e[38;2;${foreground}m${text}`e[0m"
    }
    return "`e[38;2;$foreground;48;2;${background}m${text}`e[0m"
}

$banner = @(
    "██ ██████     ████ ██████   ██████ ██████   ██ ████████   ██████ ",
    "██ ██    ██ ██     ██    ██ ██     ██    ██ ██ ██  ██  ██ ██    ██",
    "██ ██    ██ ██     ██████   ████   ██    ██ ██ ██  ██  ██ ██    ██",
    "██ ██    ██ ██████ ██    ██ ██████ ██████   ██ ██  ██  ██   ██████"
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
)


function Show-CustomBanner {
    param(
        [array]$GradientColors = @(
            @(230, 230, 230), # Dimmest white
            @(230, 230, 230),
            @(230, 230, 230),
            @(230, 230, 230),
            @(230, 230, 230),
            @(230, 230, 230)  # Brightest white
        ),
        # FFBE0B
        # FB5607
        # FF006E
        # 8338EC
        # 3A86FF
        [array]$RainbowColors = @(
            @(63, 81, 181),     # 3F51B5
            @(33, 150, 243),   # 2196F3
            @(3, 169, 244),    # 03A9F4
            @(0, 150, 136),    # 009688
            @(76, 175, 80),    # 4CAF50
            @(205, 220, 57),   # CDDC39
            @(255, 193, 7),    # FFC107
            @(255, 152, 0),    # FF9800
            @(255, 87, 34),    # FF5722
            @(244, 67, 54)     # F44336
        )
    )

    # Helper function to format colored blocks
    function Format-ColorBlock {
        param([int]$r, [int]$g, [int]$b)
        return "$([char]27)[38;2;${r};${g};${b}m██$([char]27)[0m"
    }

    $coloredArt = ""

    # Pre-generate color blocks
    $gradientBlocks = $GradientColors | ForEach-Object {
        Format-ColorBlock -r $_[0] -g $_[1] -b $_[2]
    }

    $rainbowBlocks = $RainbowColors | ForEach-Object {
        Format-ColorBlock -r $_[0] -g $_[1] -b $_[2]
    }



    foreach ($line in $banner) {
        $pos = 0
        $blockCount = 0
        $totalBlocks = ($line | Select-String "██" -AllMatches).Matches.Count

        while ($pos -lt $line.Length) {
            if ($pos + 1 -lt $line.Length -and $line.Substring($pos, 2) -eq "██") {
                if ($blockCount -ge ($totalBlocks - $rainbowBlocks.Count)) {
                    # Last blocks get rainbow colors
                    $colorIndex = $blockCount - ($totalBlocks - $rainbowBlocks.Count)
                    $coloredArt += $rainbowBlocks[$colorIndex]
                }
                elseif ($blockCount -lt $gradientBlocks.Count) {
                    # First blocks get gradient colors
                    $coloredArt += $gradientBlocks[$blockCount]
                }
                else {
                    # Middle blocks get brightest gradient color
                    $coloredArt += $gradientBlocks[-1]
                }
                $blockCount++
                $pos += 2
            }
            else {
                $coloredArt += $line[$pos]
                $pos++
            }
        }
        $coloredArt += "`n"
    }

    $osVersion = $env:OS
    $powershellVersion = $PSVersionTable.PSVersion
    $coloredArt += "$env:COMPUTERNAME | $env:USERNAME | $(Get-Date -Format 'dd-MM-yyyy hh:mm tt')`n"
    $coloredArt += "$env:PROCESSOR_ARCHITECTURE | $osVersion | PS $powershellVersion`n"
    $coloredArt += "BUILD INCREDIBLE THINGS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    Write-Host $coloredArt
}
Show-CustomBanner



# Custom prompt
$pwdLevels = 2
$post = "✨ "

function iconize {
    param(
        [string]$starting_path
    )

    $icon = @{
        "C:"        = ""
        "D:"        = "💿"
        "repo"      = "💫"
        "home"      = "🏠"
        "tools"     = "⚒️"
        "twing"     = "⚡"
        "Documents" = "🪶"
        "Downloads" = "📥"
        "Desktop"   = "🖥️"
        "Pictures"  = "🖼️"
        "Videos"    = "🎥"
        "Music"     = "🎵"
        "OneDrive"  = "🌨️"
    }
    # If starting path is in the icon hashtable, return the icon
    if ($icon.ContainsKey($starting_path)) {
        return $icon[$starting_path]
    }
    $divider = fmt ":" $colors['grey']
    $starting_path = $starting_path + $divider
    return $starting_path
}

function format-pwd {
    param(
        [string[]]$pwd
    )
    $spl = iconize $pwd[0]
    $pwd[0] = fmt $pwd[0] $colors['pink_bright']
    $pwd[1] = fmt $pwd[1] $colors['cyan_bright']
    $prompt = "$spl$divider$($pwd[1])"
    return $prompt
}

function prompt {
    $pwdresult = $pwd.ProviderPath.Split("\") | Select-Object -Last $pwdLevels
    $pwdresult = format-pwd $pwdresult
    $line = "─" * ( $pwd.ProviderPath.Split("\")[-1].Length + 1)
    $grey_line = fmt $line $colors['pink_bright']
    $linebreak = "`n"
    $pre = "$grey_line$linebreak"
    "$pre$pwdresult$post"
}

function env {
    param (
        [Parameter(Mandatory=$false, Position=0)]
        [string]$Action,
        [Parameter(Mandatory=$false, Position=1)]
        [string]$Name,
        [Parameter(Mandatory=$false, Position=2)]
        [string]$Value
    )

    function Get-TerminalWidth {
        $width = $Host.UI.RawUI.WindowSize.Width
        if ($width -le 0) {
            $width = 80
        }
        return $width
    }

    function Write-TreeView {
        param(
            [Parameter(Mandatory=$true)]
            [System.Collections.ArrayList]$Items,
            [int]$Indent = 0,
            [int]$MaxDepth = 1
        )

        $prefix = " " * $Indent
        foreach ($item in $Items) {
            $name = $item.Name
            $value = $item.Value
            if ($value -is [array]) {
                $value = $value -join ";"
            }
            $line = "$prefix- $(fmt $name $colors['green']): $(fmt $value $colors['magenta'])"
            $wrappedLines = $line -split '(?<=.{$(Get-TerminalWidth)})(?!$)'
            foreach ($wrappedLine in $wrappedLines) {
                Write-Host $wrappedLine
            }
        }
    }

    switch ($Action) {
        "list" {
            if ($Name) {
                $variables = Get-Item "env:$Name" -ErrorAction SilentlyContinue
                if ($variables) {
                    Write-TreeView -Items $variables
                }
                else {
                    Write-Host "Environment variable '$Name' not found."
                }
            }
            else {
                $variables = Get-ChildItem env: | Sort-Object Name
                Write-TreeView -Items $variables
            }
        }
        "set" {
            if (-not $Name -or -not $Value) {
                Write-Host "Usage: env set <name> <value>"
            }
            else {
                Set-EnvVariable -Name $Name -Value $Value -Permanent
            }
        }
        "add" {
            if (-not $Name -or -not $Value) {
                Write-Host "Usage: env add <name> <value>"
            }
            else {
                $existingValue = [System.Environment]::GetEnvironmentVariable($Name, [System.EnvironmentVariableTarget]::User)
                if ($existingValue) {
                    if ($existingValue -is [array]) {
                        $newValue = $existingValue + $Value
                    }
                    else {
                        $newValue = "$existingValue;$Value"
                    }
                }
                else {
                     # handle this better.
                }
                Set-EnvVariable -Name $Name -Value $newValue -Permanent
            }
        }
        default {
            Write-Host "Usage: env <list|set|add> [name] [value]"
        }
    }
}

function Set-EnvVariable {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Name,
        [Parameter(Mandatory=$true)]
        [string]$Value,
        [switch]$Permanent
    )

    # Set the environment variable for the current session
    [System.Environment]::SetEnvironmentVariable($Name, $Value)

    # If the -Permanent switch is used, also set the environment variable for the current user
    if ($Permanent) {
        $target = [System.EnvironmentVariableTarget]::User
        [System.Environment]::SetEnvironmentVariable($Name, $Value, $target)
        Write-Host "Environment variable '$Name' has been set permanently for the current user."
    }
    else {
        Write-Host "Environment variable '$Name' has been set for the current session."
    }
}

# Alias for wget
function wget {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Url,
        [string]$Output
    )

    if (-not $Output) {
        $Output = $Url | Split-Path -Leaf
    }

    Invoke-WebRequest -Uri $Url -OutFile $Output
}

# Alias for curl
function curl {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Url
    )

    Invoke-WebRequest -Uri $Url
}

# Alias for open
function open {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    Start-Process $Path
}

# Alias for clear
function clear {
    Clear-Host
}

# Alias for dirs (recursive directory listing)
function dirs {
    Get-ChildItem -Recurse | Select-Object -ExpandProperty FullName
}

# Alias for tree (directory tree listing) with color and tree structure
function tree {
    Get-ChildItem -Recurse | ForEach-Object {
        $indent = "    " * $_.FullName.Split("\").Count
        Write-Host "$indent$($_.Name)" -ForegroundColor Cyan
    }
}

# Alias for history
function history {
    Get-History
}

# Refresh the terminal, reload the profile
function refresh {
    Clear-Host
    . $PROFILE
}

# Alias for netstat
function netstat {
    Get-NetTCPConnection | Format-Table -AutoSize
}

# Alias for lsof - should list all open applications that are using network connections
# and the ports they are using in a nice table format with the process name and path
# eg
# PROCESS NAME              | PROCESS PATH                          | PORT | PROTOCOL | STATE
# --------------------------|---------------------------------------|------|----------|------
# MicrosoftEdgeCP.exe       | C:\Program Files (x86)\Microsoft\Edge | 443  | TCP      | ESTABLISHED
#  ...
function lsof {
    $netConnections = Get-NetTCPConnection | ForEach-Object {
        $proc = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
        if ($proc) {
            [PSCustomObject]@{
                "LOCAL PORT"      = $_.LocalPort
                "LOCAL ADDRESS"   = $_.LocalAddress
                "REMOTE ADDRESS"  = $_.RemoteAddress
                "REMOTE PORT"     = $_.RemotePort
                "PROCESS"         = $proc.ProcessName
                "STATE"           = $_.State
                "PROTOCOL"        = $_.Transport
                "PATH"            = $proc.Path
            }
        } else {
            [PSCustomObject]@{
                "LOCAL PORT"      = $_.LocalPort
                "LOCAL ADDRESS"   = $_.LocalAddress
                "REMOTE ADDRESS"  = $_.RemoteAddress
                "REMOTE PORT"     = $_.RemotePort
                "PROCESS"         = "Unknown"
                "STATE"           = $_.State
                "PROTOCOL"        = $_.Transport
                "PATH"            = "Unknown"
            }
        }
    }

    $netConnections | Format-Table -AutoSize
}

# Function to kill processes by name and display a message
# Example usage:
# dox "office"
function dox {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ProcessName
    )
    $successMessages = @(
        "Process '{0}' has been successfully terminated. 🎉",
        "'{0}' has been taken care of. Nothing to worry about now! 😌",
        "The termination of '{0}' is complete. Rest in peace! 🪦",
        "'{0}' has been eliminated. Mission accomplished! 🎯",
        "'{0}' won't be bothering you anymore. It's gone for good! 👋",
        "'{0}' has been sent to the digital graveyard. ⚰️",
        "The process '{0}' has been obliterated. Nothing left but bits and bytes! 💥",
        "'{0}' has been banished to the realm of deleted processes. 🔥",
        "The termination of '{0}' was a success. Another one bites the dust! 🧹",
        "'{0}' has been permanently removed from existence. Poof! 💨",
        "The process '{0}' has been sentenced to death. Execution complete! ⚖️",
        "'{0}' has been terminated with extreme prejudice. No mercy! 😈",
        "The termination of '{0}' was flawless. Like a boss! 😎",
        "'{0}' has been erased from the face of the Earth. Goodbye forever! 🌍",
        "The process '{0}' has been eliminated. Mission impossible accomplished! 🕵️",
        "'{0}' has been sent to the recycle bin. Time to take out the trash! 🗑️",
        "The termination of '{0}' was a piece of cake. Easy peasy! 🍰",
        "'{0}' has been removed from the realm of the living. Welcome to the afterlife! 👻",
        "The process '{0}' has been terminated. Another victory for the digital world! 🏆",
        "'{0}' has been destroyed. Resistance was futile! 🤖"
    )
    $failureMessages = @(
        "Yikes! Couldn't kill {0}. Must be on steroids or something. 💪",
        "Uh-oh! {0} is indestructible. Time to call the Avengers. 🦸‍♂️",
        "Oops! {0} just laughed at my attempt. 😂",
        "{0} is too strong for me. Maybe next time. 💥",
        "Error! {0} just went Super Saiyan. 🐉",
        "Wow, {0} just pulled a Houdini on me! 🎩🐰",
        "{0} just gave me the middle finger. 🖕 Rude!",
        "Apparently, {0} has a 'Get Out of Jail Free' card. 🃏"
    );

    $notFoundMessages = @(
        "Hmm... No sign of '{0}'. Probably ran away with my ex. 🏃‍♂️💔",
        "Nada found for '{0}'. Must've slipped away like a ninja. 🥷",
        "'{0}' is MIA. Maybe it joined the circus. 🎪",
        "Can't find '{0}'. It's playing hide and seek. 🤫",
        "'{0}' doesn't exist. Or does it? 👀",
        "'{0}' has vanished into thin air. 💨 Abracadabra!",
        "No trace of '{0}'. It's probably in the Bermuda Triangle. 🏝️👻",
        "'{0}' is off the grid. 🌄 Probably living its best life.",
        "'{0}' has gone incognito. 🕵️ Sneaky little process.",
        "'{0}' is on a secret mission. 🕵️ Shhh... don't blow its cover!",
        "'{0}' has eloped with a CPU core. 💍 They're on their honeymoon.",
        "'{0}' is in a parallel universe. 🌌 Beam me up, Scotty!",
        "'{0}' has gone rogue. 🤖 It's probably plotting world domination.",
        "'{0}' has taken a sabbatical. ⛱️ It'll be back... maybe.",
        "'{0}' is playing 'Where's Waldo?' 🔍 Good luck finding it!",
        "'{0}' has gone on a quest to find itself. 🌅 How deep!",
        "'{0}' has joined the Witness Protection Program. 🕵️ New identity, who dis?",
        "'{0}' has gone to a farm upstate. 🚜 It's happier there.",
        "'{0}' has been abducted by aliens. 👽 I want to believe!",
        "'{0}' has gone on a top-secret spy mission. 🕵️ It's classified!"
    )
    $processes = Get-Process -Name *$ProcessName* -ErrorAction SilentlyContinue
    if ($processes) {
        $processes | ForEach-Object {
            try {
                Stop-Process -Id $_.Id -Force -ErrorAction Stop
                $message = $successMessages | Get-Random
                Write-Host  -ForegroundColor Green ($message -f $_.ProcessName)
            } catch {
                $message = $failureMessages | Get-Random
                Write-Host  -ForegroundColor Red ($message -f $_.ProcessName)
            }
        }
    } else {
        $message = $notFoundMessages | Get-Random
        Write-Host  -ForegroundColor Yellow ($message -f $ProcessName)
    }
}

# wipe
# wrapper around rm that do not delete .git folder (deletes to recycle bin)
# also shows friendly message when deleting files
function wipe {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    $successMessages = @(
        "The file '{0}' has been successfully deleted. 🎉",
        "'{0}' has been wiped off the face of the Earth. Good riddance! 🌍",
        "The deletion of '{0}' is complete. Nothing left but bits and bytes! 💥",
        "'{0}' has been permanently removed from existence. Poof! 💨",
        "'{0}' has been sent to the digital graveyard. ⚰️",
        "The file '{0}' has been obliterated. Nothing left but a memory! 🧠",
        "'{0}' has been banished to the realm of deleted files. 🔥",
        "The deletion of '{0}' was a success. Another one bites the dust! 🧹",
        "'{0}' has been erased from the face of the Earth. Goodbye forever! 🌍",
        "The file '{0}' has been sentenced to deletion. Execution complete! ⚖️",
        "'{0}' has been terminated with extreme prejudice. No mercy! 😈",
        "The deletion of '{0}' was flawless. Like a boss! 😎",
        "'{0}' has been removed from the realm of the living. Welcome to the afterlife! 👻",
        "The file '{0}' has been eliminated. Mission impossible accomplished! 🕵️",
        "'{0}' has been sent to the recycle bin. Time to take out the trash! 🗑️",
        "The deletion of '{0}' was a piece of cake. Easy peasy! 🍰",
        "'{0}' has been destroyed. Resistance was futile! 🤖"
    )
    $failureMessages = @(
        "Yikes! Couldn't delete {0}. Must be on steroids or something. 💪",
        "Uh-oh! {0} is indestructible. Time to call the Avengers. 🦸‍♂️",
        "Oops! {0} just laughed at my attempt. 😂",
        "{0} is too strong for me. Maybe next time. 💥",
        "Error! {0} just went Super Saiyan. 🐉",
        "Wow, {0} just pulled a Houdini on me! 🎩🐰",
        "{0} just gave me the middle finger. 🖕 Rude!",
        "Apparently, {0} has a 'Get Out of Jail Free' card. 🃏"
    );

    $files = Get-ChildItem -Path $Path -Recurse -Exclude ".git" -ErrorAction SilentlyContinue

    if ($files) {
        $files | ForEach-Object {
            try {
                Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction Stop
                $message = $successMessages | Get-Random
                Write-Host  -ForegroundColor Green ($message -f $_.Name)
            } catch {
                $message = $failureMessages | Get-Random
                Write-Host  -ForegroundColor Red ($message -f $_.Name)
            }
        }
    } else {
        Write-Host  -ForegroundColor Yellow "No files found to delete."
    }

}

# Alias for clear screen as 'c'
Set-Alias -Name c -Value clear

# Alias for winget as 'w'
Set-Alias -Name w -Value winget

# Function to synchronize profile.ps1 with the repository
function sync {
    param ()

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    function Write-Log {
        param (
            [string]$Message,
            [string]$Color = "White"
        )
        Write-Host "[$timestamp] $Message" -ForegroundColor $Color
    }

    $repoPath = "C:/repo/get"
    $repoProfilePath = Join-Path -Path $repoPath -ChildPath "profile.ps1"
    $currentProfilePath = $PROFILE

    Write-Log "Starting synchronization process..." -Color "Cyan"

    if (Test-Path -Path $repoPath -PathType Container) {
        Write-Log "Repository found at '$repoPath'." -Color "Green"

        try {
            # Update profile.ps1 in the repository with the current profile content
            Copy-Item -Path $currentProfilePath -Destination $repoProfilePath -Force
            Write-Log "Updated 'profile.ps1' in the repository." -Color "Green"

            # Navigate to the repository directory
            Push-Location -Path $repoPath
            Write-Log "Changed directory to repository path." -Color "Cyan"

            # Stage changes
            git add profile.ps1
            Write-Log "Staged 'profile.ps1' for commit." -Color "Green"

            # Commit changes with a default message
            $commitMessage = "Update profile.ps1 on $(Get-Date -Format 'yyyy-MM-dd')"
            git commit -m $commitMessage
            Write-Log "Committed changes with message: '$commitMessage'." -Color "Green"

            # Push changes to the remote repository
            git push
            Write-Log "Pushed changes to the remote repository." -Color "Green"

            Write-Log "Synchronization completed successfully." -Color "Green"
        }
        catch {
            Write-Log "An error occurred during synchronization: $_" -Color "Red"
        }
        finally {
            # Return to the original directory
            Pop-Location
            Write-Log "Returned to the original directory." -Color "Cyan"
        }
    }
    else {
        Write-Log "Repository not found at '$repoPath'." -Color "Red"
    }
}

function Replace {
    <#
    .SYNOPSIS
        Recursively replaces text in ALL file/folder names and file contents.

    .DESCRIPTION
        A comprehensive search and replace function that:
        - Renames files and folders containing the search text
        - Replaces occurrences in ALL file contents
        - No automatic exclusions or restrictions
        - Uses profile's color scheme for output
        - Supports regex pattern matching

    .PARAMETER SearchText
        The text or pattern to search for.

    .PARAMETER ReplaceText
        The text to replace the SearchText with.

    .PARAMETER Path
        Optional. The starting path for the search and replace operation.
        Defaults to current directory.

    .PARAMETER ExcludeExtensions
        Optional. File extensions to exclude if desired.
        Example: @("*.exe", "*.dll")
    #>
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$SearchText,

        [Parameter(Mandatory=$true, Position=1)]
        [string]$ReplaceText,

        [Parameter(Mandatory=$false, Position=2)]
        [string]$Path = (Get-Location).Path,

        [Parameter(Mandatory=$false)]
        [string[]]$ExcludeExtensions = @()
    )

    $divider = "─" * 50
    Write-Host (fmt $divider $colors['pink_bright'])

    Write-Host (fmt "• search: " $colors['grey']) -NoNewline
    Write-Host (fmt $SearchText $colors['pink_bright'])
    Write-Host (fmt "• replace: " $colors['grey']) -NoNewline
    Write-Host (fmt $ReplaceText $colors['cyan_bright'])
    Write-Host (fmt "• path: " $colors['grey']) -NoNewline
    Write-Host (fmt $Path $colors['green'])
    if ($ExcludeExtensions) {
        Write-Host (fmt "• excluding: " $colors['grey']) -NoNewline
        Write-Host (fmt ($ExcludeExtensions -join ", ") $colors['yellow'])
    }
    Write-Host (fmt $divider $colors['pink_bright'])

    # Counter for tracking changes
    $stats = @{
        RenamedItems = 0
        UpdatedFiles = 0
        Errors = 0
    }

    # Build file filter if exclusions specified
    $fileFilter = { $true }
    if ($ExcludeExtensions) {
        $fileFilter = {
            $file = $_
            return -not ($ExcludeExtensions | Where-Object { $file.Name -like $_ })
        }
    }

    # Rename files and folders
    Get-ChildItem -Path $Path -Recurse | Where-Object $fileFilter | ForEach-Object {
        $newName = $_.Name -replace [regex]::Escape($SearchText), $ReplaceText
        if ($_.Name -ne $newName) {
            $newPath = Join-Path -Path $_.Directory.FullName -ChildPath $newName
            if (-not (Test-Path -Path $newPath)) {
                try {
                    Rename-Item -Path $_.FullName -NewName $newName -ErrorAction Stop
                    Write-Host (fmt "✓ " $colors['green']) -NoNewline
                    Write-Host (fmt "renamed: " $colors['grey']) -NoNewline
                    Write-Host (fmt $_.Name $colors['pink_bright']) -NoNewline
                    Write-Host (fmt " → " $colors['grey']) -NoNewline
                    Write-Host (fmt $newName $colors['cyan_bright'])
                    $stats.RenamedItems++
                }
                catch {
                    Write-Host (fmt "✗ " $colors['red']) -NoNewline
                    Write-Host (fmt "Failed to rename: $($_.Name) - $_" $colors['red'])
                    $stats.Errors++
                }
            }
        }
    }

    # Replace file contents
    Get-ChildItem -Path $Path -File -Recurse | Where-Object $fileFilter | ForEach-Object {
        try {
            $content = Get-Content -Path $_.FullName -Raw -ErrorAction Stop
            if ($null -eq $content) { return }

            if ($content -match [regex]::Escape($SearchText)) {
                $newContent = $content -replace [regex]::Escape($SearchText), $ReplaceText
                [System.IO.File]::WriteAllText($_.FullName, $newContent)
                Write-Host (fmt "✓ " $colors['green']) -NoNewline
                Write-Host (fmt "updated: " $colors['grey']) -NoNewline
                Write-Host (fmt $_.Name $colors['cyan_bright'])
                $stats.UpdatedFiles++
            }
        }
        catch {
            Write-Host (fmt "✗ " $colors['red']) -NoNewline
            Write-Host (fmt "Error processing $($_.Name): $_" $colors['red'])
            $stats.Errors++
        }
    }

    # Display summary
    Write-Host (fmt $divider $colors['pink_bright'])
    Write-Host (fmt "operation summary:" $colors['cyan_bright'])
    Write-Host (fmt "• items renamed: " $colors['grey']) -NoNewline
    Write-Host (fmt $stats.RenamedItems $colors['green'])
    Write-Host (fmt "• files updated: " $colors['grey']) -NoNewline
    Write-Host (fmt $stats.UpdatedFiles $colors['green'])
    if ($stats.Errors -gt 0) {
        Write-Host (fmt "• Errors encountered: " $colors['grey']) -NoNewline
        Write-Host (fmt $stats.Errors $colors['red'])
    }
    Write-Host (fmt $divider $colors['pink_bright'])
}


function Get-ContentLengths {
    param (
        [Parameter(Mandatory=$true)]
        [System.IO.FileInfo[]]$Files,
        [int]$TotalMaxLength,
        [int]$MinimumPerFile = 100
    )
    
    $fileSizes = @()
    foreach ($file in $Files) {
        try {
            $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
            $fileSizes += @{
                File = $file
                OriginalLength = $content.Length
                Content = $content
                AllocatedLength = 0
            }
        }
        catch {
            continue
        }
    }

    $fileSizes = $fileSizes | Sort-Object -Property OriginalLength -Descending
    $totalLength = ($fileSizes | Measure-Object -Property OriginalLength -Sum).Sum

    if ($totalLength -le $TotalMaxLength) {
        foreach ($file in $fileSizes) {
            $file.AllocatedLength = $file.OriginalLength
        }
        return $fileSizes
    }

    $reservedSpace = $fileSizes.Count * $MinimumPerFile
    $remainingSpace = $TotalMaxLength - $reservedSpace

    if ($remainingSpace -lt 0) {
        $evenSpace = [Math]::Floor($TotalMaxLength / $fileSizes.Count)
        foreach ($file in $fileSizes) {
            $file.AllocatedLength = $evenSpace
        }
        return $fileSizes
    }

    foreach ($file in $fileSizes) {
        $file.AllocatedLength = $MinimumPerFile
        if ($totalLength -gt 0) {
            $proportion = $file.OriginalLength / $totalLength
            $additionalSpace = [Math]::Floor($remainingSpace * $proportion)
            $file.AllocatedLength += $additionalSpace
        }
    }

    return $fileSizes
}

function Get-FileContentSummary {
    param (
        [Parameter(Mandatory=$true)]
        [System.IO.FileInfo]$File,
        [Parameter(Mandatory=$true)]
        [int]$MaxLength,
        [string]$Content = $null
    )

    # Binary files to skip
    $skipExtensions = @(
        '.exe', '.dll', '.zip', '.pdf', 
        '.doc', '.docx', '.xls', '.xlsx',
        '.jpg', '.jpeg', '.png', '.gif', 
        '.mp3', '.mp4', '.avi', '.mov'
    )

    try {
        if ($skipExtensions -contains $File.Extension.ToLower()) {
            return "Binary file - preview not available"
        }

        if (-not $Content) {
            $Content = Get-Content -Path $File.FullName -Raw -ErrorAction Stop
        }

        if ([string]::IsNullOrEmpty($Content)) {
            return "Empty file"
        }
        
        if ($MaxLength -gt 0 -and $Content.Length -gt $MaxLength) {
            $Content = $Content.Substring(0, $MaxLength) + "`n... (truncated)"
        }

        # Properly format the code block with backticks
        $codeBlock = "``````" + "`n"
        $codeBlock += $Content 
        $codeBlock += "`n``````"
        
        return $codeBlock
    }
    catch {
        return "Error reading file: $_"
    }
}

function Test-ShouldIgnorePath {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [string[]]$IgnorePatterns
    )
    
    $relativePath = $Path -replace [regex]::Escape((Get-Location)), ''
    $relativePath = $relativePath.TrimStart('\', '/')
    
    foreach ($pattern in $IgnorePatterns) {
        if ([string]::IsNullOrWhiteSpace($pattern) -or $pattern.StartsWith('#')) {
            continue
        }

        $isNegation = $pattern.StartsWith('!')
        if ($isNegation) {
            $pattern = $pattern.Substring(1)
        }

        $regex = $pattern -replace '\*\*', '.*'
        $regex = $regex -replace '\*', '[^/\\]*'
        $regex = $regex -replace '\?', '.'
        $regex = "^$regex$"

        if ($relativePath -match $regex) {
            return -not $isNegation
        }
    }

    return $false
}

function sum {
    param (
        [Parameter(Position=0)]
        [string]$Path = ".",
        [Parameter(Mandatory=$false)]
        [Alias("max")]
        [int]$MaxLength = -1,
        [switch]$IncludeHidden
    )

    if (-not (Test-Path $Path)) {
        Write-Host "Error: Path '$Path' does not exist." -ForegroundColor Red
        return
    }

    $ignorePatterns = @()
    $gitignorePath = Join-Path (Get-Location) ".gitignore"
    if (Test-Path $gitignorePath) {
        $ignorePatterns = Get-Content $gitignorePath -ErrorAction SilentlyContinue
    }

    $ignorePatterns += @(
        '.git/**',
        'node_modules/**',
        'bin/**',
        'obj/**',
        '.vs/**',
        '*.suo',
        '*.user',
        '.DS_Store'
    )

    Write-Host "SUMMARY OF: $((Resolve-Path $Path).Path)"
    Write-Host ("=" * 50)

    $allFiles = Get-ChildItem -Path $Path -Recurse -File -ErrorAction Stop -Force:$IncludeHidden | 
        Where-Object { -not (Test-ShouldIgnorePath -Path $_.FullName -IgnorePatterns $ignorePatterns) }

    $stats = @{
        TotalFiles = $allFiles.Count
        ProcessedFiles = 0
        SkippedFiles = 0
        Errors = 0
        TotalCharsShown = 0
    }

    $filesToProcess = $null
    if ($MaxLength -gt 0) {
        $filesToProcess = Get-ContentLengths -Files $allFiles -TotalMaxLength $MaxLength
    } else {
        $filesToProcess = $allFiles | ForEach-Object {
            @{
                File = $_
                AllocatedLength = -1
                Content = $null
            }
        }
    }

    foreach ($fileInfo in $filesToProcess) {
        try {
            $relativePath = $fileInfo.File.FullName -replace [regex]::Escape((Get-Location)), '.'
            
            Write-Host "`nfilename: $relativePath"
            Write-Host ("-" * 30)
            
            $summary = Get-FileContentSummary -File $fileInfo.File -MaxLength $fileInfo.AllocatedLength -Content $fileInfo.Content
            Write-Host $summary
            
            $stats.ProcessedFiles++
            if ($fileInfo.AllocatedLength -gt 0) {
                $stats.TotalCharsShown += $fileInfo.AllocatedLength
            }
        }
        catch {
            Write-Host "Error processing $($fileInfo.File.Name): $_" -ForegroundColor Red
            $stats.Errors++
        }
    }

    Write-Host "`n$("=" * 50)"
    Write-Host "STATISTICS:"
    Write-Host "• Total files found: $($stats.TotalFiles)"
    Write-Host "• Files processed: $($stats.ProcessedFiles)"
    if ($MaxLength -gt 0) {
        Write-Host "• Total chars shown: $($stats.TotalCharsShown)"
        Write-Host "• Max length limit: $MaxLength"
    }
    if ($stats.Errors -gt 0) {
        Write-Host "• Errors encountered: $($stats.Errors)" -ForegroundColor Red
    }
    Write-Host ("=" * 50)
}

Set-Alias -Name summarize -Value sum

function aifix {
    param (
        [Parameter(Position=0)]
        [string]$Path = ".",
        
        [Parameter(Position=1, Mandatory=$true)]
        [string]$Instruction,
        
        [Parameter()]
        [switch]$WhatIf
 
    )
    
    # Validate API key
    $apiKey = $env:ANTHROPIC_API_KEY
    if (-not $apiKey) {
        Write-Host "Error: ANTHROPIC_API_KEY environment variable not set" -ForegroundColor Red
        return
    }

    # Get absolute path
    $Path = Resolve-Path $Path
    if (-not $Path) {
        Write-Host "Error: Invalid path specified" -ForegroundColor Red
        return
    }

    # First, get the files using the existing logic from sum
    $ignorePatterns = @()
    $gitignorePath = Join-Path (Get-Location) ".gitignore"
    if (Test-Path $gitignorePath) {
        $ignorePatterns = Get-Content $gitignorePath -ErrorAction SilentlyContinue
    }

    $ignorePatterns += @(
        '.git/**',
        'node_modules/**',
        'bin/**',
        'obj/**',
        '.vs/**',
        '*.suo',
        '*.user',
        '.DS_Store'
    )

    # Get all files using the same logic as sum
    $allFiles = Get-ChildItem -Path $Path -Recurse -File -ErrorAction Stop | 
        Where-Object { -not (Test-ShouldIgnorePath -Path $_.FullName -IgnorePatterns $ignorePatterns) }

    if (-not $allFiles -or $allFiles.Count -eq 0) {
        Write-Host "No files found in path: $Path" -ForegroundColor Red
        return
    }

    Write-Host "`n📂 Processing" -NoNewline -ForegroundColor Cyan
    Write-Host " $($allFiles.Count) " -NoNewline -ForegroundColor Yellow
    Write-Host "files...`n" -ForegroundColor Cyan

    # Get file contents using ContentLengths
    $filesToProcess = Get-ContentLengths -Files $allFiles -TotalMaxLength 100000
    
    # Build file contents dictionary
    $fileContents = @{}
    foreach ($fileInfo in $filesToProcess) {
        try {
            $relativePath = $fileInfo.File.FullName -replace [regex]::Escape((Get-Location)), '.'
            $summary = Get-FileContentSummary -File $fileInfo.File -MaxLength $fileInfo.AllocatedLength -Content $fileInfo.Content
            
            # Strip the markdown code block markers
            $content = $summary -replace '^```\r?\n?', '' -replace '\r?\n?```$', ''
            
            if ($content -ne "Binary file - preview not available" -and 
                $content -ne "Empty file" -and 
                -not $content.StartsWith("Error reading file:")) {
                $fileContents[$relativePath] = $content
            }
        }
        catch {
            Write-Host "❌ Error processing $($fileInfo.File.Name): $_" -ForegroundColor Red
            continue
        }
    }

    if ($fileContents.Count -eq 0) {
        Write-Host "❌ No valid files found to process" -ForegroundColor Red
        return
    }

    Write-Host "📄 Found" -NoNewline -ForegroundColor Cyan
    Write-Host " $($fileContents.Count) " -NoNewline -ForegroundColor Yellow
    Write-Host "files to process" -ForegroundColor Cyan

    Write-Host "`n📋 Files found:" -ForegroundColor Cyan
    foreach ($file in $fileContents.Keys) {
        Write-Host "   • $file" -ForegroundColor Gray
    }

    # Generate prompt for Claude
    $prompt = @"
As an expert developer, modify the code according to this instruction: $Instruction

Current files:
$('-' * 50)
$(foreach ($file in $fileContents.Keys) {
@"

FILE: $file
$('-' * 30)
$($fileContents[$file])

"@
})

Provide modifications in this exact format for each file that needs to be changed:

---FILE_MODIFICATION_START---
filepath: <relative/path/to/file>
action: <modify or create>
content:```
<complete file content>
```
---FILE_MODIFICATION_END---

Important:
- Use exactly this format for each file modification
- Provide the complete new content for each file, not just the changes
- Use relative paths from the root directory
- Only include files that need to be modified or created
"@

 
        Write-Host "`nGenerated prompt:"
        Write-Host $prompt -ForegroundColor Cyan
  

    # Call Claude API
    $headers = @{
        'x-api-key' = $apiKey
        'anthropic-version' = '2023-06-01'
        'content-type' = 'application/json'
    }

    $body = @{
        model = 'claude-3-5-sonnet-20241022'
        max_tokens = 4096
        messages = @(
            @{
                role = "user"
                content = $prompt
            }
        )
    } | ConvertTo-Json -Depth 10

    try {
        Write-Host "Sending request to Claude API..."
        $response = Invoke-RestMethod `
            -Uri "https://api.anthropic.com/v1/messages" `
            -Method Post `
            -Headers $headers `
            -Body $body

        $aiResponse = $response.content.text

        if ($Debug) {
            Write-Host "`nAPI Response:"
            Write-Host $aiResponse
        }

        # Parse modifications from response
        $modPattern = '(?ms)---FILE_MODIFICATION_START---.*?filepath:\s*(?<path>.*?)[\r\n]+action:\s*(?<action>.*?)[\r\n]+content:[\r\n]+```(?<content>.*?)```[\r\n]+---FILE_MODIFICATION_END---'
        $modifications = [regex]::Matches($aiResponse, $modPattern)

        if ($modifications.Count -eq 0) {
            Write-Host "No file modifications found in AI response" -ForegroundColor Red
            return
        }

        # Preview changes
        Write-Host "`nProposed changes:"
        foreach ($mod in $modifications) {
            $filePath = $mod.Groups['path'].Value.Trim()
            $action = $mod.Groups['action'].Value.Trim()
            Write-Host "• $action`: $filePath"
        }

        if ($WhatIf) {
            Write-Host "`nWhatIf: No changes made"
            return
        }

        # Confirm changes
        $confirm = Read-Host "`nApply these changes? (y/N)"
        if ($confirm -ne 'y') {
            Write-Host "Operation cancelled"
            return
        }

        # Apply modifications
        $succeeded = 0
        $failed = 0

        foreach ($mod in $modifications) {
            $filePath = $mod.Groups['path'].Value.Trim()
            $action = $mod.Groups['action'].Value.Trim()
            $content = $mod.Groups['content'].Value

            try {
                $fullPath = Join-Path (Get-Location) $filePath
                $fullPath = [System.IO.Path]::GetFullPath($fullPath)
                
                # Security check: ensure path is within current directory
                $currentDir = [System.IO.Path]::GetFullPath((Get-Location))
                if (-not $fullPath.StartsWith($currentDir)) {
                    throw "Security violation: Path is outside current directory"
                }

                # Create directory if needed
                $directory = [System.IO.Path]::GetDirectoryName($fullPath)
                if (-not (Test-Path $directory)) {
                    New-Item -ItemType Directory -Path $directory -Force | Out-Null
                }

                # Apply change
                Set-Content -Path $fullPath -Value $content -NoNewline
                Write-Host "✓ Modified $filePath" -ForegroundColor Green
                $succeeded++
            }
            catch {
                Write-Host "✗ Failed to modify $filePath`: $_" -ForegroundColor Red
                $failed++
            }
        }

        # Report results
        Write-Host "`nResults:"
        Write-Host "• Succeeded: $succeeded"
        if ($failed -gt 0) {
            Write-Host "• Failed: $failed" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "Error: $_" -ForegroundColor Red
        if ($Debug) {
            Write-Host $_.ScriptStackTrace -ForegroundColor Red
        }
    }
}

Set-Alias -Name fix -Value aifix

 
# gitrun [github url]
# automatically clones the repo to C:\repo\<repo name> and runs it using cargo run
function gitrun {
    param (
        [Parameter(Position=0)]
        [string]$Url
    )

    try {
        # Extract repo name from URL
        $repoName = $Url -replace '.*github\.com/[^/]+/([^/]+)(\.git)?$','$1'
        if ([string]::IsNullOrEmpty($repoName)) {
            throw "Invalid GitHub URL format"
        }

        # Set target directory
        $targetDir = "C:\repo\$repoName"

        # Create parent directory if it doesn't exist
        if (-not (Test-Path "C:\repo")) {
            New-Item -ItemType Directory -Path "C:\repo" | Out-Null
        }

        # Clone the repository if it doesn't exist
        if (-not (Test-Path $targetDir)) {
            Write-Host "Cloning repository to $targetDir..." -ForegroundColor Cyan
            git clone $Url $targetDir
            if ($LASTEXITCODE -ne 0) {
                throw "Git clone failed"
            }
        }

        # Change to repo directory
        Push-Location $targetDir

        # Run with cargo
        Write-Host "Building and running with cargo..." -ForegroundColor Cyan
        cargo run

        # Return to original directory
        Pop-Location
    }
    catch {
        Write-Host "Error: $_" -ForegroundColor Red
        if ($Debug) {
            Write-Host $_.ScriptStackTrace -ForegroundColor Red
        }
    }
}

