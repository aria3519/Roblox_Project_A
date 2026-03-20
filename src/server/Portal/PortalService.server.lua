--!strict
-- PortalService: Server-side portal system.
--
-- HOW TO SET UP IN STUDIO:
--   1. Create a Model in Workspace named anything (e.g. "PortalA").
--   2. Add a Part named "Hitbox" inside – this is the invisible trigger zone.
--   3. Add a Part named "Platform" inside – where the portal sits (optional cosmetic).
--   4. Apply the CollectionService tag "Portal" to the model.
--   5. Set the attribute "PortalId" (string) on the model to link paired portals.
--      Two portals with the same PortalId form a pair (A teleports to B and vice versa).
--   6. Optionally set "PortalColor" attribute ("R,G,B") for a custom color.
--
-- The script auto-generates the visual ring; you do NOT need to build it manually.

local CollectionService = game:GetService("CollectionService")
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PortalModule = require(ReplicatedStorage.Shared.Portal.PortalModule)

-- ──────────────────────────────────────────
-- Types
-- ──────────────────────────────────────────

type PortalEntry = {
	model:   Model,
	hitbox:  BasePart,
	portalId: string,
	color:   Color3,
}

-- ──────────────────────────────────────────
-- State
-- ──────────────────────────────────────────

-- portalId → list of portal entries sharing that id (max 2 for a pair)
local portalGroups: { [string]: { PortalEntry } } = {}

-- Player UserId → tick() of last teleport (for cooldown)
local cooldowns: { [number]: number } = {}

-- ──────────────────────────────────────────
-- Ring Builder
-- ──────────────────────────────────────────

--- Builds a decorative ring of bricks around the portal hitbox.
local function buildRing(parent: Model, color: Color3): Model
	local ring = Instance.new("Model")
	ring.Name = "Ring"

	local hitbox = parent:FindFirstChild("Hitbox") :: BasePart
	local center = hitbox.Position

	local segments = PortalModule.RING_SEGMENTS
	local radius   = PortalModule.RING_RADIUS
	local segW     = PortalModule.RING_SEGMENT_W
	local segH     = PortalModule.RING_SEGMENT_H
	local segD     = PortalModule.RING_SEGMENT_D

	for i = 1, segments do
		local angle = (i / segments) * math.pi * 2
		local x = center.X + math.cos(angle) * radius
		local y = center.Y
		local z = center.Z + math.sin(angle) * radius

		local seg = Instance.new("Part")
		seg.Name       = "Segment" .. i
		seg.Size       = Vector3.new(segW, segH, segD)
		seg.CFrame     = CFrame.new(x, y, z) * CFrame.Angles(0, -angle + math.pi / 2, 0)
		seg.Anchored   = true
		seg.CanCollide = false
		seg.CastShadow = false
		seg.Material   = Enum.Material.Neon
		seg.Color      = color
		seg.Parent     = ring
	end

	-- Inner glow plane (invisible flat part used for SpecialMesh billboard)
	local glow = Instance.new("Part")
	glow.Name       = "GlowPlane"
	glow.Size       = Vector3.new(radius * 2 - 1, radius * 2 - 1, 0.05)
	glow.CFrame     = hitbox.CFrame
	glow.Anchored   = true
	glow.CanCollide = false
	glow.CastShadow = false
	glow.Material   = Enum.Material.Neon
	glow.Color      = color
	glow.Transparency = 0.6
	glow.Parent     = ring

	-- SelectionBox highlight around the glow plane for extra visual
	local selBox = Instance.new("SelectionBox")
	selBox.Adornee      = glow
	selBox.Color3       = color
	selBox.LineThickness = 0.05
	selBox.SurfaceTransparency = 1
	selBox.Parent = ring

	ring.Parent = parent
	return ring
end

-- ──────────────────────────────────────────
-- Teleportation
-- ──────────────────────────────────────────

--- Teleports a player to the destination portal.
local function teleportPlayer(player: Player, destination: PortalEntry)
	local now = tick()
	local userId = player.UserId

	-- Cooldown check
	if cooldowns[userId] and now - cooldowns[userId] < PortalModule.TELEPORT_COOLDOWN then
		return
	end
	cooldowns[userId] = now

	local rootPart = PortalModule.getRootPart(player)
	local humanoid = PortalModule.getHumanoid(player)

	if not rootPart or not humanoid then return end
	if humanoid.Health <= 0 then return end

	local destHitbox = destination.hitbox
	local destCFrame  = destHitbox.CFrame + Vector3.new(0, PortalModule.TELEPORT_HEIGHT_OFFSET, 0)

	-- Preserve horizontal look direction, override position
	rootPart.CFrame = destCFrame
end

-- ──────────────────────────────────────────
-- Portal Registration
-- ──────────────────────────────────────────

--- Registers a tagged portal model and wires up its Touched event.
local function registerPortal(model: Instance)
	if not model:IsA("Model") then
		warn("[PortalService] Tagged instance is not a Model:", model:GetFullName())
		return
	end

	local hitbox = model:FindFirstChild("Hitbox")
	if not hitbox or not hitbox:IsA("BasePart") then
		warn("[PortalService] Portal model missing 'Hitbox' part:", model:GetFullName())
		return
	end

	local portalId = model:GetAttribute(PortalModule.ATTR_PORTAL_ID)
	if typeof(portalId) ~= "string" or portalId == "" then
		warn("[PortalService] Portal missing 'PortalId' attribute:", model:GetFullName())
		return
	end

	-- Determine color
	local colorRaw = model:GetAttribute(PortalModule.ATTR_PORTAL_COLOR)
	local color: Color3
	if typeof(colorRaw) == "string" and colorRaw ~= "" then
		local ok, result = pcall(PortalModule.unpackColor, colorRaw)
		color = if ok then result else Color3.fromRGB(0, 162, 255)
	else
		color = Color3.fromRGB(0, 162, 255)
	end

	local entry: PortalEntry = {
		model    = model :: Model,
		hitbox   = hitbox :: BasePart,
		portalId = portalId,
		color    = color,
	}

	-- Add to group
	if not portalGroups[portalId] then
		portalGroups[portalId] = {}
	end
	table.insert(portalGroups[portalId], entry)

	-- Make hitbox transparent & non-collidable (it's just a trigger)
	hitbox.Transparency = 1
	hitbox.CanCollide   = false
	hitbox.Anchored     = true

	-- Build visual ring
	buildRing(model :: Model, color)

	-- Wire up Touched
	hitbox.Touched:Connect(function(part: BasePart)
		-- Find which player touched this portal
		local character = part.Parent
		if not character then return end
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		-- Find the OTHER portal in the pair
		local group = portalGroups[portalId]
		if not group or #group < 2 then
			warn("[PortalService] No paired portal found for id:", portalId)
			return
		end

		local destination: PortalEntry? = nil
		for _, other in group do
			if other.hitbox ~= hitbox then
				destination = other
				break
			end
		end

		if destination then
			teleportPlayer(player, destination)
		end
	end)

	print(string.format("[PortalService] Registered portal '%s' (id=%s)", model.Name, portalId))
end

-- ──────────────────────────────────────────
-- Initialisation
-- ──────────────────────────────────────────

-- Register portals already in workspace at start
for _, model in CollectionService:GetTagged(PortalModule.PORTAL_TAG) do
	registerPortal(model)
end

-- Register portals added at runtime (e.g. dynamically spawned)
CollectionService:GetInstanceAddedSignal(PortalModule.PORTAL_TAG):Connect(registerPortal)

-- Clean up cooldown table when players leave
Players.PlayerRemoving:Connect(function(player: Player)
	cooldowns[player.UserId] = nil
end)

print("[PortalService] Initialized.")
