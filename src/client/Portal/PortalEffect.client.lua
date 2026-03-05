--!strict
-- PortalEffect: Client-side visual effects for portals.
--
-- Responsibilities:
--   • Spins the ring segments on each portal continuously.
--   • Pulses the glow plane transparency.
--   • Adds a ParticleEmitter and PointLight to each portal's GlowPlane.
--   • Plays a sound when the local player enters a portal.
--
-- This script is purely cosmetic – all gameplay logic lives in PortalService (server).

local CollectionService = game:GetService("CollectionService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService      = game:GetService("SoundService")
local TweenService      = game:GetService("TweenService")

local PortalModule = require(ReplicatedStorage.Shared.Portal.PortalModule)

-- ──────────────────────────────────────────
-- Constants
-- ──────────────────────────────────────────

local RING_SPIN_SPEED = 1.2   -- Full rotations per second
local GLOW_TWEEN_TIME = 0.8   -- Seconds for one pulse half-cycle
local LIGHT_RANGE     = 20    -- PointLight range (studs)
local LIGHT_BRIGHTNESS = 2

-- ──────────────────────────────────────────
-- Helpers
-- ──────────────────────────────────────────

--- Creates a ParticleEmitter and attaches it to the given part.
local function addParticles(part: BasePart, color: Color3)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color        = ColorSequence.new({
		ColorSequenceKeypoint.new(0, color),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, color),
	})
	emitter.LightEmission  = 1
	emitter.LightInfluence = 0
	emitter.Size           = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.3, 0.4),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Speed        = NumberRange.new(2, 6)
	emitter.SpreadAngle  = Vector2.new(30, 30)
	emitter.Rate         = 40
	emitter.Lifetime     = NumberRange.new(0.6, 1.2)
	emitter.Rotation     = NumberRange.new(0, 360)
	emitter.RotSpeed     = NumberRange.new(-90, 90)
	emitter.Parent       = part
end

--- Creates a PointLight and attaches it to the given part.
local function addLight(part: BasePart, color: Color3)
	local light = Instance.new("PointLight")
	light.Color      = color
	light.Range      = LIGHT_RANGE
	light.Brightness = LIGHT_BRIGHTNESS
	light.Parent     = part
end

--- Sets up a looping glow pulse tween on the glow plane.
local function startGlowPulse(glowPlane: BasePart)
	local tweenInfo = TweenInfo.new(
		GLOW_TWEEN_TIME,
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut,
		-1,   -- repeat forever
		true  -- reverse (ping-pong)
	)
	local tween = TweenService:Create(glowPlane, tweenInfo, { Transparency = 0.85 })
	tween:Play()
end

--- Spins all ring segments of a portal every frame.
local function startRingSpin(ring: Model, color: Color3)
	-- Collect segments (exclude GlowPlane and SelectionBox)
	local segments: { BasePart } = {}
	for _, child in ring:GetChildren() do
		if child:IsA("BasePart") and child.Name ~= "GlowPlane" then
			table.insert(segments, child :: BasePart)
		end
	end

	local angle = 0
	local count = #segments
	if count == 0 then return end

	RunService.RenderStepped:Connect(function(dt: number)
		angle = angle + RING_SPIN_SPEED * dt * math.pi * 2

		-- Shift each segment's position around the ring
		local radius = PortalModule.RING_RADIUS
		for i, seg in segments do
			local baseAngle = ((i - 1) / count) * math.pi * 2
			local a = baseAngle + angle
			local originCFrame = seg.CFrame
			local newPos = Vector3.new(
				originCFrame.Position.X, -- x will be recalculated below
				originCFrame.Position.Y,
				originCFrame.Position.Z
			)
			-- Rotate around the ring's local Y axis.
			-- Use the glow plane center as pivot.
			local glowPlane = ring:FindFirstChild("GlowPlane") :: BasePart?
			if glowPlane then
				local center = glowPlane.Position
				newPos = Vector3.new(
					center.X + math.cos(a) * radius,
					center.Y,
					center.Z + math.sin(a) * radius
				)
				seg.CFrame = CFrame.new(newPos) * CFrame.Angles(0, -a + math.pi / 2, 0)
			end
		end
	end)
end

-- ──────────────────────────────────────────
-- Portal Setup
-- ──────────────────────────────────────────

local function setupPortalEffects(model: Instance)
	if not model:IsA("Model") then return end

	-- Wait for the ring to be built by the server (may take a moment after replication)
	local ring: Model? = nil
	local deadline = tick() + 5
	while tick() < deadline do
		local found = model:FindFirstChild("Ring")
		if found and found:IsA("Model") then
			ring = found :: Model
			break
		end
		task.wait(0.1)
	end

	if not ring then
		warn("[PortalEffect] Ring not found on portal:", model:GetFullName())
		return
	end

	-- Determine color from attribute
	local colorRaw = model:GetAttribute(PortalModule.ATTR_PORTAL_COLOR)
	local color: Color3
	if typeof(colorRaw) == "string" and colorRaw ~= "" then
		local ok, result = pcall(PortalModule.unpackColor, colorRaw)
		color = if ok then result else Color3.fromRGB(0, 162, 255)
	else
		color = Color3.fromRGB(0, 162, 255)
	end

	local glowPlane = ring:FindFirstChild("GlowPlane") :: BasePart?
	if glowPlane then
		addParticles(glowPlane, color)
		addLight(glowPlane, color)
		startGlowPulse(glowPlane)
	end

	startRingSpin(ring, color)
end

-- ──────────────────────────────────────────
-- Initialisation
-- ──────────────────────────────────────────

-- Handle portals already present
for _, model in CollectionService:GetTagged(PortalModule.PORTAL_TAG) do
	task.spawn(setupPortalEffects, model)
end

-- Handle portals added at runtime
CollectionService:GetInstanceAddedSignal(PortalModule.PORTAL_TAG):Connect(function(model)
	task.spawn(setupPortalEffects, model)
end)

print("[PortalEffect] Initialized.")
