-- MonsterSystem/MonsterSpawner.lua
-- Script: ServerScriptService에 배치
-- Workspace 안의 이름이 "MonsterSpawner"인 파트를 감지해 몬스터를 소환합니다.
--
-- [스포너 파트 설정 방법]
-- 1. Workspace에 Part를 생성하고 이름을 "MonsterSpawner"로 변경
-- 2. Part의 Attribute 추가 (Properties > Attributes):
--    - MonsterType  (string) : "Goblin" / "Orc" / "Skeleton" / "Troll"
--    - MaxCount     (number) : 동시에 최대 몇 마리까지 유지할지 (기본 3)
--    - SpawnInterval(number) : 몇 초마다 소환 시도할지 (기본 10)

local ServerStorage  = game:GetService("ServerStorage")
local Workspace      = game:GetService("Workspace")
local MonsterStats   = require(script.Parent:WaitForChild("MonsterStats"))
local MonsterAI      = script.Parent:WaitForChild("MonsterAI")

-- 스포너별 소환된 몬스터 카운트 추적
local spawnerData = {} -- [spawnerPart] = { monsters = {} }

-- ==============================
-- 몬스터 모델 동적 생성
-- ==============================
local function buildMonsterModel(monsterType, stats)
	local model = Instance.new("Model")
	model.Name = monsterType

	-- HumanoidRootPart (이동 기준)
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Transparency = 1
	root.CanCollide = false
	root.Parent = model

	-- 몸통
	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.BrickColor = BrickColor.new(stats.Color)
	torso.Material = Enum.Material.SmoothPlastic
	torso.Parent = model

	-- 머리
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.5, 1.5, 1.5)
	head.BrickColor = BrickColor.new(stats.Color)
	head.Material = Enum.Material.SmoothPlastic
	head.Parent = model

	-- 이름 빌보드
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 100, 0, 30)
	billboard.StudsOffset = Vector3.new(0, 3.5, 0)
	billboard.AlwaysOnTop = false
	billboard.Parent = head

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.Text = monsterType
	nameLabel.Parent = billboard

	-- Humanoid
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = stats.Health
	humanoid.Health = stats.Health
	humanoid.WalkSpeed = stats.Speed
	humanoid.Parent = model

	-- Weld: Torso ↔ Root
	local weldRoot = Instance.new("WeldConstraint")
	weldRoot.Part0 = root
	weldRoot.Part1 = torso
	weldRoot.Parent = model

	-- Weld: Torso ↔ Head
	local weldHead = Instance.new("WeldConstraint")
	weldHead.Part0 = torso
	weldHead.Part1 = head
	weldHead.Parent = model

	model.PrimaryPart = root

	-- 스텟을 Attribute로 저장 (MonsterAI가 읽음)
	model:SetAttribute("MonsterType",     monsterType)
	model:SetAttribute("Damage",          stats.Damage)
	model:SetAttribute("AttackRange",     stats.AttackRange)
	model:SetAttribute("AttackCooldown",  stats.AttackCooldown)
	model:SetAttribute("DetectRange",     stats.DetectRange)

	-- AI 스크립트 복사 삽입
	local aiScript = MonsterAI:Clone()
	aiScript.Parent = model

	return model
end

-- ==============================
-- 소환 처리
-- ==============================
local function spawnMonster(spawnerPart, monsterType, stats)
	local data = spawnerData[spawnerPart]

	-- 죽은 몬스터 정리
	for i = #data.monsters, 1, -1 do
		local m = data.monsters[i]
		if not m or not m.Parent then
			table.remove(data.monsters, i)
		else
			local hum = m:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health <= 0 then
				table.remove(data.monsters, i)
			end
		end
	end

	local maxCount = spawnerPart:GetAttribute("MaxCount") or 3
	if #data.monsters >= maxCount then return end

	local monster = buildMonsterModel(monsterType, stats)

	-- 스포너 위치 근처에 랜덤 배치
	local offset = Vector3.new(math.random(-4, 4), 3, math.random(-4, 4))
	monster:PivotTo(CFrame.new(spawnerPart.Position + offset))
	monster.Parent = Workspace

	table.insert(data.monsters, monster)
end

-- ==============================
-- 스포너 파트 등록 & 루프
-- ==============================
local function registerSpawner(spawnerPart)
	local monsterType = spawnerPart:GetAttribute("MonsterType")
	if not monsterType then
		warn("[MonsterSpawner] MonsterType Attribute가 없습니다: " .. spawnerPart:GetFullName())
		return
	end

	local stats = MonsterStats.Get(monsterType)
	if not stats then return end

	-- 스포너 시각화
	spawnerPart.BrickColor = BrickColor.new("Bright red")
	spawnerPart.Material = Enum.Material.Neon
	spawnerPart.Transparency = 0.6
	spawnerPart.Anchored = true
	spawnerPart.CanCollide = false

	spawnerData[spawnerPart] = { monsters = {} }

	local interval = spawnerPart:GetAttribute("SpawnInterval") or 10

	-- 소환 루프
	task.spawn(function()
		while spawnerPart and spawnerPart.Parent do
			spawnMonster(spawnerPart, monsterType, stats)
			task.wait(interval)
		end
		spawnerData[spawnerPart] = nil
	end)

	print(("[MonsterSpawner] 스포너 등록: %s → %s (간격: %ds, 최대: %d)"):format(
		spawnerPart.Name, monsterType, interval,
		spawnerPart:GetAttribute("MaxCount") or 3
	))
end

-- ==============================
-- Workspace에서 스포너 파트 수집
-- ==============================
local function findSpawners()
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name == "MonsterSpawner" then
			registerSpawner(obj)
		end
	end
end

-- 나중에 추가되는 스포너도 감지
Workspace.DescendantAdded:Connect(function(obj)
	if obj:IsA("BasePart") and obj.Name == "MonsterSpawner" then
		task.wait() -- 속성 로드 대기
		registerSpawner(obj)
	end
end)

findSpawners()
print("[MonsterSpawner] 몬스터 스포너 시스템 시작됨")
