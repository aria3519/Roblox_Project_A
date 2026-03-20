--!strict
-- SimplePortal: A 지점 → B 지점 단방향 포탈
--
-- 사용법:
--   1. Workspace에 Part 두 개를 만든다.
--   2. 아래 PORTAL_A_NAME, PORTAL_B_NAME에 그 Part 이름을 입력한다.
--   3. 끝.

local PORTAL_A_NAME = "PortalA"   -- 들어가는 포탈 Part 이름
local PORTAL_B_NAME = "PortalB"   -- 나오는 목적지 Part 이름
local COOLDOWN      = 2           -- 재사용 대기 시간 (초)

-- ──────────────────────────────────────────

local Players  = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local portalA = Workspace:WaitForChild(PORTAL_A_NAME) :: BasePart
local portalB = Workspace:WaitForChild(PORTAL_B_NAME) :: BasePart

-- 포탈 A를 반투명하게 (선택)
portalA.Transparency = 0.5
portalA.BrickColor   = BrickColor.new("Bright blue")
portalA.Material     = Enum.Material.Neon
portalA.CanCollide   = false

local cooldowns: { [number]: number } = {}

portalA.Touched:Connect(function(hit: BasePart)
	local character = hit.Parent
	if not character then return end

	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end

	local now = tick()
	if cooldowns[player.UserId] and now - cooldowns[player.UserId] < COOLDOWN then
		return
	end
	cooldowns[player.UserId] = now

	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end

	-- 목적지 위 5스터드로 텔레포트
	root.CFrame = portalB.CFrame + Vector3.new(0, 5, 0)
end)

-- 나간 플레이어 쿨다운 정리
Players.PlayerRemoving:Connect(function(player: Player)
	cooldowns[player.UserId] = nil
end)

print("[SimplePortal] 포탈 준비 완료: " .. PORTAL_A_NAME .. " → " .. PORTAL_B_NAME)
