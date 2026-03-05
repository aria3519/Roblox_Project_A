-- MonsterSystem/MonsterAI.lua
-- Script: 몬스터 모델 안에 자동 삽입됨 (MonsterSpawner가 Clone해서 넣음)
-- 가장 가까운 플레이어를 감지해 추적 및 공격합니다.

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local monster   = script.Parent
local humanoid  = monster:WaitForChild("Humanoid")
local rootPart  = monster:WaitForChild("HumanoidRootPart")

-- 스포너가 Attribute로 심어준 스텟 읽기
local DAMAGE         = monster:GetAttribute("Damage")         or 10
local ATTACK_RANGE   = monster:GetAttribute("AttackRange")    or 5
local ATTACK_COOLDOWN= monster:GetAttribute("AttackCooldown") or 1.5
local DETECT_RANGE   = monster:GetAttribute("DetectRange")    or 30
local MONSTER_TYPE   = monster:GetAttribute("MonsterType")    or "Unknown"

local canAttack = true
local isDead    = false

-- ==============================
-- 가장 가까운 플레이어 탐색
-- ==============================
local function getNearestPlayer()
	local nearest, minDist = nil, DETECT_RANGE

	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if not char then continue end
		local root = char:FindFirstChild("HumanoidRootPart")
		local hum  = char:FindFirstChildOfClass("Humanoid")
		if not root or not hum or hum.Health <= 0 then continue end

		local dist = (rootPart.Position - root.Position).Magnitude
		if dist < minDist then
			minDist = dist
			nearest = char
		end
	end

	return nearest, minDist
end

-- ==============================
-- 공격
-- ==============================
local function attackCharacter(targetChar)
	if not canAttack then return end
	canAttack = false

	local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
	if targetHum and targetHum.Health > 0 then
		targetHum:TakeDamage(DAMAGE)
	end

	task.delay(ATTACK_COOLDOWN, function()
		canAttack = true
	end)
end

-- ==============================
-- AI 루프 (0.1초 간격)
-- ==============================
local function aiLoop()
	while not isDead and humanoid.Health > 0 do
		local target, dist = getNearestPlayer()

		if target then
			local targetRoot = target:FindFirstChild("HumanoidRootPart")
			if targetRoot then
				if dist <= ATTACK_RANGE then
					-- 공격 사정거리 안 → 이동 멈추고 공격
					humanoid:MoveTo(rootPart.Position)
					attackCharacter(target)
				else
					-- 감지 범위 안 → 추적
					humanoid:MoveTo(targetRoot.Position)
				end
			end
		else
			-- 감지 범위 안에 플레이어 없음 → 정지
			humanoid:MoveTo(rootPart.Position)
		end

		task.wait(0.1)
	end
end

-- ==============================
-- 사망 처리
-- ==============================
humanoid.Died:Connect(function()
	isDead = true
	-- 사망 후 3초 뒤 모델 제거 (스포너가 카운트 정리함)
	task.delay(3, function()
		if monster and monster.Parent then
			monster:Destroy()
		end
	end)
end)

-- ==============================
-- 시작
-- ==============================
task.spawn(aiLoop)
