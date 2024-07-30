
# implement show function
function show($color, $message) {
    Write-Host $message -ForegroundColor $color
}

$green = "Green"
$yellow = "Yellow"
$red = "Red"# constants for colors





show yellow "commiting changes"
git add .
git commit -m "bump version"
git push


