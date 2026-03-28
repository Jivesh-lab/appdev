$file = 'G:\appdev\lib\teacher\teacher_screens.dart'
$content = Get-Content $file -Raw -Encoding UTF8

# Find the specific broken spot: closing brace of _endClass followed directly by 'return Scaffold'
# Pattern: line with only '  }' then whitespace/newlines then '    return Scaffold('
$pattern = "(?s)(  \}\s*\r?\n)\s*(return Scaffold\()"
$replacement = "`$1`r`n  @override`r`n  Widget build(BuildContext context) {`r`n    return Scaffold("

$fixed = [System.Text.RegularExpressions.Regex]::Replace($content, $pattern, $replacement, 1)

if ($fixed -ne $content) {
    Set-Content -Path $file -Value $fixed -NoNewline -Encoding UTF8
    Write-Host "Fixed: @override + build() inserted before return Scaffold"
} else {
    Write-Host "Pattern not matched - showing lines around 'return Scaffold':"
    $lines = Get-Content $file
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "return Scaffold") {
            Write-Host "$($i+1): $($lines[$i-2])"
            Write-Host "$($i+1): $($lines[$i-1])"
            Write-Host "$($i+1): $($lines[$i])"
        }
    }
}
Write-Host "Done. Lines: $((Get-Content $file).Count)"
