$BASE = 'http://localhost:8000/api'
$testEmail = "teacher_p4_$(Get-Random)@classpulse.test"
$testPass = 'test1234'

function Pass($msg) { Write-Host "  PASS  $msg" -ForegroundColor Green }
function Fail($msg) { Write-Host "  FAIL  $msg" -ForegroundColor Red }

Write-Host '===============================================' -ForegroundColor Cyan
Write-Host '   ClassPulse Backend — Phase 4 Test Suite    ' -ForegroundColor Cyan
Write-Host '===============================================' -ForegroundColor Cyan

# ── Setup: Signup + Login + Create Session + Student Join ─────────────────────
Write-Host "`n[SETUP] Creating teacher, session, student..." -ForegroundColor Yellow

# Signup
$body = @{ name='P4 Teacher'; email=$testEmail; password=$testPass; role='teacher' } | ConvertTo-Json
Invoke-RestMethod -Uri "$BASE/auth/signup" -Method POST -Body $body -ContentType 'application/json' | Out-Null

# Login → get JWT
$loginBody = @{ email=$testEmail; password=$testPass } | ConvertTo-Json
$r = Invoke-RestMethod -Uri "$BASE/auth/login" -Method POST -Body $loginBody -ContentType 'application/json'
$token = $r.token
$headers = @{ Authorization = "Bearer $token" }
Write-Host "  INFO  Teacher logged in. JWT: $($token.Substring(0,20))..." -ForegroundColor Gray

# Create session
$sessionBody = @{ className='Physics 101'; classCode='PHY' } | ConvertTo-Json
$r = Invoke-RestMethod -Uri "$BASE/sessions/create" -Method POST -Body $sessionBody -ContentType 'application/json' -Headers $headers
$sessionCode = $r.session.code
Write-Host "  INFO  Session created: $sessionCode" -ForegroundColor Gray

# Student joins
$joinBody = @{ studentName='Bob'; studentEmail='bob@test.com' } | ConvertTo-Json
$r = Invoke-RestMethod -Uri "$BASE/sessions/$sessionCode/join" -Method POST -Body $joinBody -ContentType 'application/json'
$studentToken = $r.anonymous_student_token
Write-Host "  INFO  Student joined. Token: $($studentToken.Substring(0,8))..." -ForegroundColor Gray

# ── Phase 4 Tests: Questions API ──────────────────────────────────────────────
Write-Host "`n[PHASE 4] Questions API" -ForegroundColor Yellow

# Test 1: Student submits a question (Public)
$qBody = @{ text='Can you explain Newton second law?'; student_token=$studentToken } | ConvertTo-Json
$r = Invoke-RestMethod -Uri "$BASE/sessions/$sessionCode/questions" -Method POST -Body $qBody -ContentType 'application/json'
if ($r.success -and $r.question.id) {
  Pass "POST /api/sessions/:code/questions (question created)"
  $questionId = $r.question.id
} else { Fail "POST /api/sessions/:code/questions" }

# Test 2: Student submits a second question
$qBody2 = @{ text='What is the difference between mass and weight?'; student_token=$studentToken } | ConvertTo-Json
$r2 = Invoke-RestMethod -Uri "$BASE/sessions/$sessionCode/questions" -Method POST -Body $qBody2 -ContentType 'application/json'
if ($r2.success -and $r2.question.id) { Pass "POST /api/sessions/:code/questions (second question)" }
else { Fail "POST second question" }

# Test 3: Question without text → 400
try {
  $qBad = @{ text=''; student_token=$studentToken } | ConvertTo-Json
  Invoke-RestMethod -Uri "$BASE/sessions/$sessionCode/questions" -Method POST -Body $qBad -ContentType 'application/json' | Out-Null
  Fail "Empty question text should be rejected"
} catch {
  if ($_.Exception.Response.StatusCode.value__ -eq 400) { Pass "Empty question text rejected (400)" }
  else { Fail "Unexpected status: $($_.Exception.Response.StatusCode.value__)" }
}

# Test 4: Question without student_token → 400
try {
  $qNoToken = @{ text='Valid question?' } | ConvertTo-Json
  Invoke-RestMethod -Uri "$BASE/sessions/$sessionCode/questions" -Method POST -Body $qNoToken -ContentType 'application/json' | Out-Null
  Fail "Missing student_token should be rejected"
} catch {
  if ($_.Exception.Response.StatusCode.value__ -eq 400) { Pass "Missing student_token rejected (400)" }
  else { Fail "Unexpected status: $($_.Exception.Response.StatusCode.value__)" }
}

# Test 5: Teacher gets all questions (Protected)
$r = Invoke-RestMethod -Uri "$BASE/sessions/$sessionCode/questions" -Method GET -Headers $headers
if ($r.success -and $r.questions.Count -eq 2) {
  Pass "GET /api/sessions/:code/questions (2 questions returned)"
} else { Fail "GET questions. Count=$($r.questions.Count)" }

# Test 6: Get questions without token → 401
try {
  Invoke-RestMethod -Uri "$BASE/sessions/$sessionCode/questions" -Method GET | Out-Null
  Fail "GET questions without token should be 401"
} catch {
  if ($_.Exception.Response.StatusCode.value__ -eq 401) { Pass "GET questions without token rejected (401)" }
  else { Fail "Unexpected: $($_.Exception.Response.StatusCode.value__)" }
}

# Test 7: Question is not answered initially
$r = Invoke-RestMethod -Uri "$BASE/sessions/$sessionCode/questions" -Method GET -Headers $headers
$firstQuestion = $r.questions[0]
if ($firstQuestion.isAnswered -eq $false) { Pass "Question.isAnswered is false by default" }
else { Fail "Question.isAnswered should be false: $($firstQuestion.isAnswered)" }

# Test 8: Teacher marks question as answered (Protected)
$r = Invoke-RestMethod -Uri "$BASE/sessions/$sessionCode/questions/$questionId/answer" -Method PATCH -Headers $headers
if ($r.success -and $r.isAnswered -eq $true) { Pass "PATCH /api/sessions/:code/questions/:id/answer (marked answered)" }
else { Fail "PATCH mark answered: $($r | ConvertTo-Json)" }

# Test 9: Verify question is now marked answered
$r = Invoke-RestMethod -Uri "$BASE/sessions/$sessionCode/questions" -Method GET -Headers $headers
$updatedQ = $r.questions | Where-Object { $_.id -eq $questionId }
if ($updatedQ.isAnswered -eq $true) { Pass "GET questions - answered question shows isAnswered=true" }
else { Fail "isAnswered should be true for question $questionId" }

# Test 10: Non-existent question → 404
try {
  Invoke-RestMethod -Uri "$BASE/sessions/$sessionCode/questions/99999/answer" -Method PATCH -Headers $headers | Out-Null
  Fail "Non-existent question should return 404"
} catch {
  if ($_.Exception.Response.StatusCode.value__ -eq 404) { Pass "Non-existent question returns 404" }
  else { Fail "Unexpected: $($_.Exception.Response.StatusCode.value__)" }
}

# Test 11: Mark answered without token → 401
try {
  Invoke-RestMethod -Uri "$BASE/sessions/$sessionCode/questions/$questionId/answer" -Method PATCH | Out-Null
  Fail "Mark answered without token should be 401"
} catch {
  if ($_.Exception.Response.StatusCode.value__ -eq 401) { Pass "Mark answered without token rejected (401)" }
  else { Fail "Unexpected: $($_.Exception.Response.StatusCode.value__)" }
}

# Test 12: Question submitted to ended session → 410
$r = Invoke-RestMethod -Uri "$BASE/sessions/$sessionCode/end" -Method POST -Headers $headers
Write-Host "  INFO  Session ended." -ForegroundColor Gray
try {
  Invoke-RestMethod -Uri "$BASE/sessions/$sessionCode/questions" -Method POST -Body $qBody -ContentType 'application/json' | Out-Null
  Fail "Submitting question to ended session should return 410"
} catch {
  if ($_.Exception.Response.StatusCode.value__ -eq 410) { Pass "Question to ended session returns 410" }
  else { Fail "Unexpected: $($_.Exception.Response.StatusCode.value__)" }
}

# Test 13: Summary includes correct question_count
$r = Invoke-RestMethod -Uri "$BASE/sessions/$sessionCode/summary" -Method GET -Headers $headers
if ($r.success -and $r.summary.questionCount -eq 2) { Pass "Session summary includes questionCount=2" }
else { Fail "Summary questionCount wrong: $($r.summary.questionCount)" }

Write-Host "`n===============================================" -ForegroundColor Cyan
Write-Host '          Phase 4 Tests Complete!             ' -ForegroundColor Cyan
Write-Host "===============================================`n" -ForegroundColor Cyan
