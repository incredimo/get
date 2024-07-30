
# implement show function
function show($color, $message) {
    Write-Host $message -ForegroundColor $color
}

 
show "yellow" "commiting changes"
git add .
git commit -m "bump version"
git push

show "green" "changes committed"