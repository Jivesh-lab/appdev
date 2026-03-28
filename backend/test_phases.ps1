$BASE = 'http://localhost:8000/api'
$testEmail = "teacher_test_$(Get-Random)@classpulse.test"
$testPass = 'test1234'
$token = ''
$sessionCode = ''

Write-Host '===============================================' -ForegroundColor Cyan
Write-Host '  ClassPulse Backend  Phase 1-3 Test Suite    ' -ForegroundColor Cyan
Write-Host '===============================================' -ForegroundColor Cyan

function Pass($msg) { Write-Host "  PASS  $msg" -ForegroundColor Green }
function Fail($msg) { Write-Host "  FAIL  $msg" -ForegroundColor Red }

# ─── PHASE 1: Auth Hardening ──────────────────────────────────────────────────
Write-Host "`n[PHASE 1] Auth Hardening" -ForegroundColor Yellow

# Test 1: Health check
$r = Invoke-RestMethod -Uri "$BASE/health" -Method GET
if ($r.success) { Pass "GET /api/health" } else { Fail "GET /api/health" }

# Test 2: Signup
$body = @{ name='Test Teacher'; email=$testEmail; password=$testPass; role='teacher' } | ConvertTo-Json
$r = Invoke-RestMethod -Uri "$BASE/auth/signup" -Method POST -Body $body -ContentType 'application/json'
if ($r.success) { Pass "POST /api/auth/signup" } else { Fail "POST /api/auth/signup" }

# Test 3: Duplicate signup should 400
try {
  Invoke-RestMethod -Uri "$BASE/auth/signup" -Method POST -Body $body -ContentType 'application/json' | Out-Null
  Fail "Duplicate signup should be rejected"
} catch {
  if ($_.Exception.Response.StatusCode.value__ -eq 400) { Pass "Duplicate signup rejected (400)" }
  else { Fail "Unexpected status: $($_.Exception.Response.StatusCode.value__)" }
}

# Test 4: Login returns JWT
$loginBody = @{ email=$testEmail; password=$testPass } | ConvertTo-Json
$r = Invoke-RestMethod -Uri "$BASE/auth/login" -Method POST -Body $loginBody -ContentType 'application/json'
if ($r.success -and $r.token) {
  Pass "POST /api/auth/login => JWT returned"
  $token = $r.token
  $userId = $r.user.id
} else { Fail "POST /api/auth/login" }

# Test 5: Protected route without token => 401
try {
  Invoke-RestMethod -Uri "$BASE/users/$userId" -Method GET | Out-Null
  Fail "/users/:id without token should return 401"
} catch {
  if ($_.Exception.Response.StatusCode.value__ -eq 401) { Pass "Protected route blocked without token (401)" }
  else { Fail "Unexpected status: $($_.Exception.Response.StatusCode.value__)" }
}

# Test 6: Protected route WITH token => 200
$headers = @{ Authorization = "Bearer $token" }
$r = Invoke-RestMethod -Uri "$BASE/users/$userId" -Method GET -Headers $headers
if ($r.success -and $r.user) { Pass "Protected route accessible with token (200)" }
else { Fail "GET /api/users/:id with token" }

# ─── PHASE 2: Session Lifecycle ───────────────────────────────────────────────
Write-Host "`n[PHASE 2] Session Lifecycle" -ForegroundColor Yellow

# Test 7: Create session (protected)
$sessionBody = @{ className='Math 101'; classCode='MATH' } | ConvertTo-Json
$r = Invoke-RestMethod -Uri "$BASE/sessions/create" -Method POST -Body $sessionBody -ContentType 'application/json' -Headers $headers
if ($r.success -and $r.session.code) {
  Pass "POST /api/sessions/create"
  $sessionCode = $r.session.code
} else { Fail "POST /api/sessions/create" }

# Test 8: Create session without token => 401
try {
  Invoke-RestMethod -Uri "$BASE/sessions/create" -Method POST -Body $sessionBody -ContentType 'application/json' | Out-Null
  Fail "Session create without token should be 401"
} catch {
  if ($_.Exception.Response.StatusCode.value__ -eq 401) { Pass "Session create without token rejected (401)" }
  else { Fail "Unexpected: $($_.Exception.Response.StatusCode.value__)" }
}

# Test 9: Get session (public)
$r = Invoke-RestMethod -Uri "$BASE/sessions/$sessionCode" -Method GET
if ($r.success -and $r.session.sessionCode -eq $sessionCode) { Pass "GET /api/sessions/:code (public)" }
else { Fail "GET /api/sessions/:code" }

# Test 10: Student joins session
$joinBody = @{ studentName='Alice'; studentEmail='alice@test.com' } | ConvertTo-Json
$r = Invoke-RestMethod -Uri "$BASE/sessions/$sessionCode/join" -Method POST -Body $joinBody -ContentType 'application/json'
if ($r.success -and $r.anonymous_student_token) {
  Pass "POST /api/sessions/:code/join (student token returned)"
  $studentToken = $r.anonymous_student_token
} else { Fail "POST /api/sessions/:code/join" }

# ─── PHASE 3: Feedback Signal APIs ────────────────────────────────────────────
Write-Host "`n[PHASE 3] Feedback Signal APIs" -ForegroundColor Yellow

# Test 11: Submit feedback signal
$fbBody = @{ signal='lost'; student_token=$studentToken } | ConvertTo-Json
$r = Invoke-RestMethod -Uri "$BASE/sessions/$sessionCode/feedback" -Method POST -Body $fbBody -ContentType 'application/json'
if ($r.received -and $r.signal -eq 'lost') { Pass "POST /api/sessions/:code/feedback (lost signal)" }
else { Fail "POST /api/sessions/:code/feedback" }

# Test 12: Change signal (upsert)
$fbBody2 = @{ signal='got_it'; student_token=$studentToken } | ConvertTo-Json
$r = Invoke-RestMethod -Uri "$BASE/sessions/$sessionCode/feedback" -Method POST -Body $fbBody2 -ContentType 'application/json'
if ($r.received -and $r.signal -eq 'got_it') { Pass "POST /api/sessions/:code/feedback (signal changed upsert)" }
else { Fail "Upsert failed" }

# Test 13: Invalid signal => 400
try {
  $fbBad = @{ signal='confused'; student_token=$studentToken } | ConvertTo-Json
  Invoke-RestMethod -Uri "$BASE/sessions/$sessionCode/feedback" -Method POST -Body $fbBad -ContentType 'application/json' | Out-Null
  Fail "Invalid signal should be rejected"
} catch {
  if ($_.Exception.Response.StatusCode.value__ -eq 400) { Pass "Invalid signal rejected (400)" }
  else { Fail "Unexpected: $($_.Exception.Response.StatusCode.value__)" }
}

# Test 14: Aggregate (protected)
$r = Invoke-RestMethod -Uri "$BASE/sessions/$sessionCode/feedback/aggregate" -Method GET -Headers $headers
if ($r.success -and $r.got_it -eq 1) { Pass "GET /api/sessions/:code/feedback/aggregate (got_it=1, upsert verified)" }
else { Fail "GET aggregate. got_it=$($r.got_it)" }

# Test 15: Update threshold (protected)
$threshBody = @{ threshold=50 } | ConvertTo-Json
$r = Invoke-RestMethod -Uri "$BASE/sessions/$sessionCode/threshold" -Method PATCH -Body $threshBody -ContentType 'application/json' -Headers $headers
if ($r.updated -and $r.threshold -eq 50) { Pass "PATCH /api/sessions/:code/threshold" }
else { Fail "PATCH threshold" }

# Test 16: End session (protected)
$r = Invoke-RestMethod -Uri "$BASE/sessions/$sessionCode/end" -Method POST -Headers $headers
if ($r.success -and $r.summary) { Pass "POST /api/sessions/:code/end" }
else { Fail "POST end session" }

# Test 17: Get summary (protected)
$r = Invoke-RestMethod -Uri "$BASE/sessions/$sessionCode/summary" -Method GET -Headers $headers
if ($r.success -and $r.summary.sessionCode) { Pass "GET /api/sessions/:code/summary" }
else { Fail "GET summary" }

# Test 18: Join ended session => 410
try {
  Invoke-RestMethod -Uri "$BASE/sessions/$sessionCode/join" -Method POST -Body $joinBody -ContentType 'application/json' | Out-Null
  Fail "Joining ended session should return 410"
} catch {
  if ($_.Exception.Response.StatusCode.value__ -eq 410) { Pass "Joining ended session returns 410" }
  else { Fail "Unexpected status: $($_.Exception.Response.StatusCode.value__)" }
}

Write-Host "`n===============================================" -ForegroundColor Cyan
Write-Host '          All Phase 1-3 Tests Complete!       ' -ForegroundColor Cyan
Write-Host "===============================================`n" -ForegroundColor Cyan
