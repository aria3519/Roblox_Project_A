-- SimplePortal/PortalScript.lua
-- 포탈 A에서 포탈 B로 플레이어를 순간이동시키는 스크립트
-- ServerScriptService 안에 넣거나 각 포탈 파트의 자식 Script로 사용하세요.

local TeleportCooldowns = {} -- 쿨다운 테이블 (중복 텔레포트 방지)
local COOLDOWN_TIME = 2      -- 텔레포트 후 재사용 대기 시간(초)

-- 포탈 파트 참조 (Workspace 안의 이름으로 찾습니다)
local workspace = game:GetService("Workspace")
local PortalA = workspace:WaitForChild("PortalA")
local PortalB = workspace:WaitForChild("PortalB")

-- 포탈 이펙트 설정 (선택 사항: 파티클 등이 있으면 활성화)
local function setupPortalVisuals(portal, color)
	portal.BrickColor = BrickColor.new(color)
	portal.Material = Enum.Material.Neon
	portal.Transparency = 0.4
	portal.Anchored = true
	portal.CanCollide = false

	-- 포탈 위에 빌보드 GUI 라벨 추가
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 120, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = portal

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = portal.Name
	label.Parent = billboard
end

-- 플레이어의 캐릭터를 목적지 포탈 위치로 이동
local function teleportPlayer(character, destination)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		-- 목적지 포탈 위 1.5스터드 위치로 이동 (포탈 안에 끼지 않도록)
		rootPart.CFrame = destination.CFrame + Vector3.new(0, 3, 0)
	end
end

-- 쿨다운 확인 및 텔레포트 실행
local function onTouched(portal, destination, hit)
	local character = hit.Parent
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	local player = game:GetService("Players"):GetPlayerFromCharacter(character)
	if not player then return end

	-- 쿨다운 확인
	if TeleportCooldowns[player.UserId] then return end

	TeleportCooldowns[player.UserId] = true
	teleportPlayer(character, destination)

	-- 쿨다운 해제
	task.delay(COOLDOWN_TIME, function()
		TeleportCooldowns[player.UserId] = nil
	end)
end

-- 포탈 시각 설정
setupPortalVisuals(PortalA, "Bright blue")
setupPortalVisuals(PortalB, "Bright orange")

-- 포탈 터치 이벤트 연결
PortalA.Touched:Connect(function(hit)
	onTouched(PortalA, PortalB, hit)
end)

PortalB.Touched:Connect(function(hit)
	onTouched(PortalB, PortalA, hit)
end)

print("포탈 시스템이 활성화되었습니다!")
