$file = 'G:\appdev\lib\teacher\teacher_screens.dart'
$lines = Get-Content $file

# Remove lines 1511-1585 (0-indexed: 1510-1584)
# These are stale remnant code from the old camera container
$newLines = $lines[0..1509] + $lines[1585..($lines.Count - 1)]

Set-Content -Path $file -Value $newLines -Encoding UTF8
Write-Host "Removed stale lines 1511-1585. New count: $($newLines.Count)"
