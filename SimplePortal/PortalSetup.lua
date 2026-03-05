-- SimplePortal/PortalSetup.lua
-- Workspace에 포탈 파트 두 개를 자동으로 생성하는 설정 스크립트
-- Studio에서 한 번만 실행하거나, ServerScriptService에 넣어 런타임에 생성하세요.

local workspace = game:GetService("Workspace")

local function createPortal(name, position, color)
	-- 기존 파트가 있으면 재사용
	local existing = workspace:FindFirstChild(name)
	if existing then
		return existing
	end

	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.new(4, 8, 1)   -- 가로 4, 높이 8, 두께 1
	part.Position = position
	part.BrickColor = BrickColor.new(color)
	part.Material = Enum.Material.Neon
	part.Transparency = 0.4
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part.Parent = workspace

	return part
end

-- 포탈 A : 기본 위치 (0, 5, 0)
createPortal("PortalA", Vector3.new(0, 5, 0),   "Bright blue")

-- 포탈 B : 기본 위치 (0, 5, 50) — 50스터드 앞
createPortal("PortalB", Vector3.new(0, 5, 50),  "Bright orange")

print("포탈 파트 생성 완료! PortalA -> PortalB 위치를 원하는 곳으로 이동하세요.")
