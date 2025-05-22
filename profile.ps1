# ██  ██████      ████  ██████    ██████  ██████    ██  ████████    ██████
# ██  ██    ██  ██      ██    ██  ██      ██    ██  ██  ██  ██  ██  ██    ██
# ██  ██    ██  ██      ██████    ████    ██    ██  ██  ██  ██  ██  ██    ██
# ██  ██    ██  ██████  ██    ██  ██████  ██████    ██  ██  ██  ██    ██████

#  █ █▀▀▄ ▄▀▀ █▀█ █▀▀ █▀▀▄ █ █▀█▀▄ █▀▀▄
#  █ █  █ █▄▄ █▀▄ ██▄ █▄▄▀ █ █ █ █ ▀▄▄█

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

# $banner = @(
#     "██ ██████     ████ ██████   ██████ ██████   ██ ████████   ██████ ",
#     "██ ██    ██ ██     ██    ██ ██     ██    ██ ██ ██  ██  ██ ██    ██",
#     "██ ██    ██ ██     ██████   ████   ██    ██ ██ ██  ██  ██ ██    ██",
#     "██ ██    ██ ██████ ██    ██ ██████ ██████   ██ ██  ██  ██   ██████"
#     "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
# )


#  █ █▀▀▄ ▄▀▀ █▀█ █▀▀ █▀▀▄ █ █▀█▀▄ █▀▀▄
#  █ █  █ █▄▄ █▀▄ ██▄ █▄▄▀ █ █ █ █ ▀▄▄█
# Banner art: you can mix block characters (e.g., █, ▄, or ▀)
# $banner = @(
#     "█ █▀▀▄ ▄▀▀ █▀█ █▀▀ █▀▀▄ █ █▀█▀▄ █▀▀▄  AGHIL KUTTIKATIL MOHANDAS",
#     "█ █  █ █▄▄ █▀▄ ██▄ █▄▄▀ █ █ █ █ ▀▄▄█  a@xo.rs | incredimo.com "
#     "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
# )

# Define the block characters we want to process.
$blockChars = @("█", "▄", "▀")

# Define your rainbow color palette (RGB values) exactly as before.
$RainbowColors = @(
    @(63,81,181),    # 3F51B5
    @(33,150,243),   # 2196F3
    @(3,169,244),    # 03A9F4
    @(0,150,136),    # 009688
    @(76,175,80),    # 4CAF50
    @(205,220,57),   # CDDC39
    @(255,193,7),    # FFC107
    @(255,152,0),    # FF9800
    @(255,87,34),    # FF5722
    @(244,67,54)     # F44336
)

# Define white as the base color (RGB for white).
$WhiteRGB = @(255,255,255)

# Helper function: wraps a character with ANSI escape codes for the given RGB color.
function Format-Block {
    param(
        [Parameter(Mandatory=$true)] [string]$char,
        [Parameter(Mandatory=$true)] [int]$r,
        [Parameter(Mandatory=$true)] [int]$g,
        [Parameter(Mandatory=$true)] [int]$b
    )
    return "$([char]27)[38;2;${r};${g};${b}m$char$([char]27)[0m"
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


# Main function that builds the banner:
# - Accepts an angle (in degrees) for the gradient.
# - Accepts a white threshold which is the fraction of the gradient (0 to 1) that stays white.
# function Show-CustomBanner {
#     param(
#         [double]$Angle = 45.0,         # Angle in degrees (default is 45°)
#         [double]$WhiteThreshold = 0.3    # Fraction of the projection range that remains white.
#     )

#     # Convert the angle from degrees to radians.
#     $theta = $Angle * [Math]::PI / 180.0

#     # First pass: determine the maximum projection value among all block characters.
#     # Projection for each block = (column * cos(theta) + row * sin(theta))
#     $maxProj = 0.0
#     for ($row = 0; $row -lt $banner.Count; $row++) {
#         $line = $banner[$row]
#         for ($col = 0; $col -lt $line.Length; $col++) {
#             $char = $line[$col]
#             if ($blockChars -contains $char) {
#                 $proj = $col * [Math]::Cos($theta) + $row * [Math]::Sin($theta)
#                 if ($proj -gt $maxProj) { $maxProj = $proj }
#             }
#         }
#     }

#     # Build the colored banner output.
#     $coloredArt = ""
#     for ($row = 0; $row -lt $banner.Count; $row++) {
#         $line = $banner[$row]
#         $lineOutput = ""
#         for ($col = 0; $col -lt $line.Length; $col++) {
#             $char = $line[$col]
#             if ($blockChars -contains $char) {
#                 # Compute the projection of this block.
#                 $proj = $col * [Math]::Cos($theta) + $row * [Math]::Sin($theta)
#                 # Compute the relative position (ratio) along the gradient [0, 1]
#                 $ratio = if ($maxProj -eq 0) { 0 } else { $proj / $maxProj }
                
#                 if ($ratio -lt $WhiteThreshold) {
#                     # If the ratio is below the white threshold, render the block in white.
#                     $lineOutput += Format-Block -char $char -r $WhiteRGB[0] -g $WhiteRGB[1] -b $WhiteRGB[2]
#                 }
#                 else {
#                     # Otherwise, scale the ratio into the rainbow range.
#                     $relativeRainbow = ($ratio - $WhiteThreshold) / (1 - $WhiteThreshold)
#                     $index = [Math]::Round($relativeRainbow * ($RainbowColors.Count - 1))
#                     if ($index -ge $RainbowColors.Count) { $index = $RainbowColors.Count - 1 }
#                     $color = $RainbowColors[$index]
#                     $lineOutput += Format-Block -char $char -r $color[0] -g $color[1] -b $color[2]
#                 }
#             }
#             else {
#                 # Characters that aren't in $blockChars are output unchanged.
#                 $lineOutput += $char
#             }
#         }
#         $coloredArt += $lineOutput + "`n"
#     }

 

#     Write-Host $coloredArt
# }

# # --- Usage Examples ---

# # Full range gradient at a 45° angle with 30% white at the beginning.
# Show-CustomBanner -Angle 45 -WhiteThreshold 0.45

# For example, try a different angle (like 60°) and adjust the white threshold as needed:
# Show-CustomBanner -Angle 60 -WhiteThreshold 0.2

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




function sum {
    param (
        [Parameter(Position=0)]
        [string]$Path = ".",
        
        [Parameter(Mandatory=$false)]
        [Alias("m")]
        [int]$MaxLength = 100000,
        
        [Parameter(Mandatory=$false)]
        [Alias("a")]
        [switch]$All,
        
        [Parameter(Mandatory=$false)]
        [Alias("nc")]
        [switch]$NoClipboard,
        
        [Parameter(Mandatory=$false)]
        [Alias("h")]
        [switch]$Hidden,
        
        [Parameter(Mandatory=$false)]
        [switch]$Help,
        
        [Parameter(Mandatory=$false)]
        [Alias("f")]
        [string[]]$FileFilter,
        
        [Parameter(Mandatory=$false)]
        [Alias("i")]
        [string[]]$IgnoreDirs,
        
        [Parameter(Mandatory=$false)]
        [Alias("s")]
        [switch]$Structure
    )

    # Display help if requested
    if ($Help) {
        $helpText = @"
USAGE:
    sum [PATH] [OPTIONS]

DESCRIPTION:
    Summarizes code files in a directory for easy sharing with LLMs.
    Automatically copies output to clipboard unless disabled.

ARGUMENTS:
    PATH                    Directory to summarize (default: current directory)

OPTIONS:
    -MaxLength, -m VALUE    Maximum character length for output (default: 100000)
    -All, -a                Include non-code files in output
    -NoClipboard, -nc       Don't copy output to clipboard
    -Hidden, -h             Include hidden files and directories
    -Structure, -s          Only output project structure, no file contents
    -FileFilter, -f VALUE   Additional file extensions to include (e.g., "*.txt")
    -IgnoreDirs, -i VALUE   Additional directories to ignore
    -Help                   Show this help information

EXAMPLES:
    sum                     # Summarize code in current directory
    sum C:\projects\myapp   # Summarize code in specified directory
    sum -a                  # Include all files, not just code files
    sum -m 50000            # Limit output to 50,000 characters
    sum -f "*.md","*.txt"   # Include markdown and text files
    sum -i "temp","logs"    # Ignore "temp" and "logs" directories
    sum -s                  # Show only structure, no file contents
"@
        Write-Host $helpText
        return
    }

    # Common code file extensions
    $codeExtensions = @(
        # Web
        '*.html', '*.css', '*.scss', '*.sass', '*.less', '*.js', '*.jsx', '*.ts', '*.tsx', 
        '*.vue', '*.svelte', '*.php',
        # Programming languages
        '*.py', '*.rb', '*.go', '*.rs', '*.java', '*.cs', '*.cpp', '*.c', '*.h', '*.hpp',
        '*.swift', '*.kt', '*.scala', '*.clj', '*.fs', '*.ex', '*.exs', '*.erl', '*.lua',
        # Shell/Scripts
        '*.sh', '*.bash', '*.ps1', '*.bat', '*.cmd', '*.psm1',
        # Config files
        '*.json', '*.yaml', '*.yml', '*.toml', '*.xml', '*.ini', '*.config', '*.conf',
        '*.md', '*.rst',
        # Other code files
        '*.sql', '*.graphql', '*.proto', '*.tf', '*.dockerfile', '*.r'
    )

    # Add custom file filters if provided
    if ($FileFilter) {
        $codeExtensions += $FileFilter
    }

    # Directories to always exclude
    $excludeDirs = @(
        # Package managers
        'node_modules', 'packages', 'vendor', '.npm', '.yarn', 'bower_components',
        # Build artifacts
        'bin', 'obj', 'dist', 'build', 'target', 'out', 'output', 'coverage', '.next',
        # Cache directories
        '__pycache__', '.pytest_cache', '.cache', '.nuget', '.gradle',
        # IDE/Config folders
        '.git', '.idea', '.vs', '.vscode', 
        # Misc
        'assets/images', 'public/images'
    )

    # Add custom dirs to ignore if provided
    if ($IgnoreDirs) {
        $excludeDirs += $IgnoreDirs
    }

    # Files to always exclude
    $excludeFiles = @(
        # Binaries and compiled files
        '*.exe', '*.dll', '*.pdb', '*.so', '*.dylib', '*.class',
        # Large data files
        '*.zip', '*.tar', '*.gz', '*.rar', '*.7z', 
        '*.jpg', '*.jpeg', '*.png', '*.gif', '*.bmp', '*.ico', '*.svg',
        '*.mp3', '*.mp4', '*.avi', '*.mov', '*.wav',
        '*.pdf', '*.doc', '*.docx', '*.xls', '*.xlsx', '*.ppt', '*.pptx',
        # Logs and caches
        '*.log', '*.cache', '*.bak', '*.swp', '*.tmp', '*.temp',
        # Lock files
        '*.lock', '*.lock.json', '*.lockb', 'package-lock.json', 'yarn.lock',
        # OS artifacts
        '.DS_Store', 'Thumbs.db'
    )

    # Create separate builders for console and clipboard
    $consoleOutput = [System.Text.StringBuilder]::new()
    $clipboardOutput = [System.Text.StringBuilder]::new()
    
    # Function to append text to appropriate outputs
    function Write-Output-Both {
        param (
            [string]$Text,
            [System.ConsoleColor]$ForegroundColor = [System.ConsoleColor]::White,
            [switch]$SkipClipboard
        )
        
        # Always write to console with color
        Write-Host $Text -ForegroundColor $ForegroundColor
        [void]$consoleOutput.AppendLine($Text)
        
        # For clipboard, skip if flagged
        if (-not $SkipClipboard) {
            [void]$clipboardOutput.AppendLine($Text)
        }
    }

    if (-not (Test-Path $Path)) {
        Write-Output-Both "Error: Path '$Path' does not exist." -ForegroundColor Red
        return
    }

    # Calculate absolute path for display
    $absolutePath = (Resolve-Path $Path).Path
    Write-Output-Both "PROJECT SUMMARY: $absolutePath" -ForegroundColor Cyan

    # Find gitignore patterns if exists
    $ignorePatterns = @()
    $gitignorePath = Join-Path $absolutePath ".gitignore"
    if (Test-Path $gitignorePath) {
        $ignorePatterns = Get-Content $gitignorePath -ErrorAction SilentlyContinue | 
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and -not $_.StartsWith('#') }
    }

    # Build file filter
    $fileFilter = {
        $file = $_
        $relativePath = $file.FullName.Substring($absolutePath.Length).TrimStart('/', '\')
        
        # Check if in excluded directory
        foreach ($dir in $excludeDirs) {
            if ($relativePath -match "[\\/]$dir[\\/]" -or $relativePath -match "^$dir[\\/]") {
                return $false
            }
        }
        
        # Check gitignore patterns
        foreach ($pattern in $ignorePatterns) {
            $regex = $pattern -replace '\.', '\.' -replace '\*\*', '.*' -replace '\*', '[^/\\]*' -replace '\?', '.'
            if ($relativePath -match $regex) {
                return $false
            }
        }
        
        # Check file pattern exclusions
        foreach ($pattern in $excludeFiles) {
            if ($file.Name -like $pattern) {
                return $false
            }
        }
        
        # Filter for code files if not including non-code
        if (-not $All) {
            $isCodeFile = $false
            foreach ($ext in $codeExtensions) {
                if ($file.Name -like $ext) {
                    $isCodeFile = $true
                    break
                }
            }
            return $isCodeFile
        }
        
        return $true
    }

    # Get all files, applying our filter
    $allFiles = Get-ChildItem -Path $Path -Recurse -File -Force:$Hidden -ErrorAction SilentlyContinue |
        Where-Object $fileFilter | Sort-Object LastWriteTime -Descending

    $stats = @{
        TotalFiles = $allFiles.Count
        ProcessedFiles = 0
        TotalSizeMB = [math]::Round(($allFiles | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
    }

    if ($allFiles.Count -eq 0) {
        Write-Output-Both "No code files found after applying filters." -ForegroundColor Yellow
        return
    }

    Write-Output-Both "Found $($stats.TotalFiles) files (Total size: $($stats.TotalSizeMB) MB)" -ForegroundColor Cyan

    # Get file content lengths and allocate space
    $filesToProcess = Get-ContentLengths -Files $allFiles -TotalMaxLength $MaxLength

    # Process directory structure for a tree-like overview
    $dirStructure = @{}
    foreach ($fileInfo in $filesToProcess) {
        $relativePath = $fileInfo.File.FullName.Substring($absolutePath.Length).TrimStart('/', '\')
        $dirPath = [System.IO.Path]::GetDirectoryName($relativePath)
        
        if (-not $dirPath) { $dirPath = "." }
        
        if (-not $dirStructure.ContainsKey($dirPath)) {
            $dirStructure[$dirPath] = @()
        }
        
        $dirStructure[$dirPath] += @{
            Name = [System.IO.Path]::GetFileName($fileInfo.File.FullName)
            Size = [math]::Round($fileInfo.File.Length / 1KB, 2)
        }
    }

    # Output directory structure
    Write-Output-Both "`nPROJECT STRUCTURE:" -ForegroundColor Cyan
    $dirPaths = $dirStructure.Keys | Sort-Object
    foreach ($dir in $dirPaths) {
        $indent = "  " * ($dir.Split('\', '/').Count - 1)
        $dirName = if ($dir -eq ".") { "." } else { $dir.Split('\', '/')[-1] }
        Write-Output-Both "$indent$dirName/" -ForegroundColor Yellow
        
        foreach ($file in $dirStructure[$dir]) {
            $fileIndent = $indent + "  "
            Write-Output-Both "$fileIndent$($file.Name) (${$file.Size}KB)" -ForegroundColor Gray
        }
    }

    # If structure-only mode, skip file contents
    if (-not $Structure) {
        # Output file contents
        Write-Output-Both "`nFILE CONTENTS:" -ForegroundColor Cyan -SkipClipboard
        Write-Output-Both "`nFILE CONTENTS:"
        
        foreach ($fileInfo in $filesToProcess) {
            try {
                $relativePath = $fileInfo.File.FullName.Substring($absolutePath.Length).TrimStart('/', '\')
                $lastModified = $fileInfo.File.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                $sizeKB = [math]::Round($fileInfo.File.Length / 1KB, 2)
                
                Write-Output-Both "`nFILE: $relativePath [$lastModified, ${sizeKB}KB]" -ForegroundColor Yellow -SkipClipboard
                Write-Output-Both "`nFILE: $relativePath [$lastModified, ${sizeKB}KB]"
                
                $content = $fileInfo.Content
                if (-not $content) {
                    $content = Get-Content -Path $fileInfo.File.FullName -Raw -ErrorAction Stop
                }
                
                if ($fileInfo.AllocatedLength -gt 0 -and $content.Length -gt $fileInfo.AllocatedLength) {
                    $content = $content.Substring(0, $fileInfo.AllocatedLength) + "`n... (truncated, file is larger)"
                }
                
                if ([string]::IsNullOrEmpty($content)) {
                    Write-Output-Both "Empty file" -ForegroundColor Gray -SkipClipboard
                    Write-Output-Both "Empty file"
                } else {
                    # Determine language for code fence based on extension
                    $ext = [System.IO.Path]::GetExtension($fileInfo.File.Name).TrimStart('.')
                    $lang = switch ($ext) {
                        { $_ -in @('js', 'jsx', 'ts', 'tsx') } { 'javascript' }
                        { $_ -in @('py') } { 'python' }
                        { $_ -in @('rs') } { 'rust' }
                        { $_ -in @('go') } { 'go' }
                        { $_ -in @('c', 'cpp', 'h', 'hpp') } { 'cpp' }
                        { $_ -in @('cs') } { 'csharp' }
                        { $_ -in @('java') } { 'java' }
                        { $_ -in @('rb') } { 'ruby' }
                        { $_ -in @('php') } { 'php' }
                        { $_ -in @('ps1', 'psm1') } { 'powershell' }
                        { $_ -in @('sh', 'bash') } { 'bash' }
                        { $_ -in @('html') } { 'html' }
                        { $_ -in @('css', 'scss', 'sass') } { 'css' }
                        { $_ -in @('json') } { 'json' }
                        { $_ -in @('xml') } { 'xml' }
                        { $_ -in @('yaml', 'yml') } { 'yaml' }
                        { $_ -in @('md', 'markdown') } { 'markdown' }
                        { $_ -in @('sql') } { 'sql' }
                        default { '' }
                    }
                    
                    Write-Output-Both "```$lang" -ForegroundColor Gray -SkipClipboard
                    Write-Output-Both "```$lang"
                    Write-Output-Both $content -ForegroundColor Gray -SkipClipboard
                    Write-Output-Both $content
                    Write-Output-Both "```" -ForegroundColor Gray -SkipClipboard
                    Write-Output-Both "```"
                }
                
                $stats.ProcessedFiles++
            }
            catch {
                Write-Output-Both "Error processing $($fileInfo.File.Name): $_" -ForegroundColor Red -SkipClipboard
                Write-Output-Both "Error processing $($fileInfo.File.Name): $_"
            }
        }
    }

    # Output summary statistics
    Write-Output-Both "`nSTATISTICS:" -ForegroundColor Cyan -SkipClipboard
    Write-Output-Both "`nSTATISTICS:"
    Write-Output-Both "Total files found: $($stats.TotalFiles)" -ForegroundColor Gray -SkipClipboard
    Write-Output-Both "Total files found: $($stats.TotalFiles)"
    Write-Output-Both "Files processed: $($stats.ProcessedFiles)" -ForegroundColor Gray -SkipClipboard
    Write-Output-Both "Files processed: $($stats.ProcessedFiles)"
    Write-Output-Both "Total size: $($stats.TotalSizeMB) MB" -ForegroundColor Gray -SkipClipboard
    Write-Output-Both "Total size: $($stats.TotalSizeMB) MB"
    
    if ($MaxLength -gt 0) {
        Write-Output-Both "Character limit: $MaxLength" -ForegroundColor Gray -SkipClipboard
        Write-Output-Both "Character limit: $MaxLength"
    }

    # Copy output to clipboard if not disabled
    if (-not $NoClipboard) {
        $clipboardString = $clipboardOutput.ToString()
        
        # Try to copy to clipboard
        try {
            $clipboardString | Set-Clipboard
            Write-Host "`nProject summary copied to clipboard ($($clipboardString.Length) characters)" -ForegroundColor Green
        }
        catch {
            Write-Host "`nFailed to copy to clipboard: $_" -ForegroundColor Red
        }
    }
    
    return $clipboardOutput.ToString()
}

Set-Alias -Name summarize -Value sum