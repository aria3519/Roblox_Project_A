-- Equipment/SwordTool.lua
-- Roblox Tool(검) 장비 스크립트
-- Tool 오브젝트의 자식 Script로 배치하세요.
-- Tool 구조: Tool > Handle(Part) > SwordTool(Script)

-- ==============================
-- 설정값
-- ==============================
local DAMAGE       = 25     -- 공격 시 데미지
local ATTACK_RANGE = 5      -- 공격 범위 (스터드)
local COOLDOWN     = 0.6    -- 공격 쿨다운 (초)
local SWING_ANIM_ID = ""    -- 스윙 애니메이션 ID (예: "rbxassetid://1234567890"), 없으면 빈 문자열

-- ==============================
-- 내부 변수
-- ==============================
local Tool      = script.Parent
local Handle    = Tool:WaitForChild("Handle")
local Players   = game:GetService("Players")
local RunService = game:GetService("RunService")

local canAttack = true
local swingAnim = nil

-- ==============================
-- 유틸리티
-- ==============================

-- 캐릭터와 Humanoid 가져오기
local function getCharacterAndHumanoid()
	local player = Players:GetPlayerFromCharacter(Tool.Parent)
	if not player then return nil, nil end
	local character = Tool.Parent
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return character, humanoid
end

-- ==============================
-- 스윙 애니메이션
-- ==============================

local function loadAnimation(humanoid)
	if SWING_ANIM_ID == "" then return nil end
	local anim = Instance.new("Animation")
	anim.AnimationId = SWING_ANIM_ID
	return humanoid:LoadAnimation(anim)
end

-- ==============================
-- 근접 공격 처리
-- ==============================

local function dealDamage()
	local character, humanoid = getCharacterAndHumanoid()
	if not character or not humanoid then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- 범위 내 모든 캐릭터를 검색해 데미지 적용
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		local otherChar = otherPlayer.Character
		if not otherChar or otherChar == character then continue end

		local otherRoot = otherChar:FindFirstChild("HumanoidRootPart")
		local otherHumanoid = otherChar:FindFirstChildOfClass("Humanoid")

		if otherRoot and otherHumanoid and otherHumanoid.Health > 0 then
			local distance = (rootPart.Position - otherRoot.Position).Magnitude
			if distance <= ATTACK_RANGE then
				otherHumanoid:TakeDamage(DAMAGE)
			end
		end
	end
end

-- ==============================
-- 공격 실행
-- ==============================

local function onActivate()
	if not canAttack then return end
	canAttack = false

	local _, humanoid = getCharacterAndHumanoid()

	-- 스윙 애니메이션 재생
	if humanoid then
		if not swingAnim then
			swingAnim = loadAnimation(humanoid)
		end
		if swingAnim then
			swingAnim:Play()
		end
	end

	-- 데미지 적용 (애니메이션 중반쯤 타이밍)
	task.delay(0.15, dealDamage)

	-- 쿨다운 해제
	task.delay(COOLDOWN, function()
		canAttack = true
	end)
end

-- ==============================
-- Tool 장착/해제 처리
-- ==============================

Tool.Equipped:Connect(function()
	canAttack = true
	swingAnim = nil -- 장착 시 애니메이션 재로드 대비 초기화
end)

Tool.Unequipped:Connect(function()
	if swingAnim then
		swingAnim:Stop()
	end
	swingAnim = nil
	canAttack = false
end)

Tool.Activated:Connect(onActivate)

print(Tool.Name .. " 무기 스크립트가 로드되었습니다. (데미지: " .. DAMAGE .. ", 범위: " .. ATTACK_RANGE .. "스터드)")
