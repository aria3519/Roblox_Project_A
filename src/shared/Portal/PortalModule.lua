--!strict
-- PortalModule: Shared configuration and utility functions for the portal system.
-- Used by both server (PortalService) and client (PortalEffect).

local PortalModule = {}

-- ──────────────────────────────────────────
-- Types
-- ──────────────────────────────────────────

export type PortalConfig = {
	id: string,           -- Unique identifier matching a paired portal
	color: Color3,        -- Tint color for the portal ring/particles
	teamColor: BrickColor?, -- Optional: only teleports players of this BrickColor team
}

-- ──────────────────────────────────────────
-- Constants
-- ──────────────────────────────────────────

-- Tag applied to every portal model in the workspace (via CollectionService).
PortalModule.PORTAL_TAG = "Portal"

-- Attribute names stored on the portal model.
PortalModule.ATTR_PORTAL_ID    = "PortalId"    -- string  – links two portals together
PortalModule.ATTR_PORTAL_COLOR = "PortalColor" -- string  – "R,G,B" packed color

-- Cooldown (seconds) before a player can be teleported again.
PortalModule.TELEPORT_COOLDOWN = 2

-- Height offset added to the teleport destination so the player lands
-- cleanly above the portal platform.
PortalModule.TELEPORT_HEIGHT_OFFSET = 5

-- Portal ring construction settings.
PortalModule.RING_SEGMENTS   = 24   -- Number of brick segments in the ring
PortalModule.RING_RADIUS     = 8    -- Radius of the ring (studs)
PortalModule.RING_SEGMENT_W  = 2    -- Width of each segment
PortalModule.RING_SEGMENT_H  = 1    -- Height of each segment
PortalModule.RING_SEGMENT_D  = 0.5  -- Depth (thickness) of each segment

-- ──────────────────────────────────────────
-- Utility Functions
-- ──────────────────────────────────────────

--- Packs a Color3 value into a storable "R,G,B" string (0–255).
function PortalModule.packColor(color: Color3): string
	return string.format(
		"%d,%d,%d",
		math.round(color.R * 255),
		math.round(color.G * 255),
		math.round(color.B * 255)
	)
end

--- Unpacks a "R,G,B" string back into a Color3.
function PortalModule.unpackColor(packed: string): Color3
	local r, g, b = packed:match("^(%d+),(%d+),(%d+)$")
	assert(r and g and b, "[PortalModule] Invalid packed color: " .. packed)
	return Color3.fromRGB(tonumber(r) :: number, tonumber(g) :: number, tonumber(b) :: number)
end

--- Returns the HumanoidRootPart of a player's character, or nil if not available.
function PortalModule.getRootPart(player: Player): BasePart?
	local character = player.Character
	if not character then return nil end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

--- Returns the Humanoid of a player's character, or nil if not available.
function PortalModule.getHumanoid(player: Player): Humanoid?
	local character = player.Character
	if not character then return nil end
	return character:FindFirstChildOfClass("Humanoid") :: Humanoid?
end

return PortalModule
