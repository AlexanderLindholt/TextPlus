--!optimize 2

-- Services.
local CollectionService = game:GetService("CollectionService")

-- Attempt to find the plugin object.
local plugin = script:FindFirstAncestorOfClass("Plugin")

-- Options list for validation.
local optionsList = require(script.Parent.Options)

-- Default defaults.
local defaults = {
	Font = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
	
	Size = 14,
	
	ScaleSize = nil,
	MinimumSize = nil,
	MaximumSize = nil,
	
	Color = Color3.fromRGB(0, 0, 0),
	Transparency = 0,
	
	Pixelated = false,
	
	Offset = Vector2.zero,
	Rotation = 0,
	
	StrokeSize = 5,
	StrokeColor = Color3.fromRGB(0, 0, 0),
	
	ShadowOffset = Vector2.new(0, 20),
	ShadowColor = Color3.fromRGB(50, 50, 50),
	
	LineHeight = 1,
	CharacterSpacing = 1,
	
	Truncate = false,
	
	XAlignment = "Left",
	YAlignment = "Top",
	
	WordSorting = false,
	LineSorting = false,
	
	Dynamic = false
}

-- Merge user defaults.
local userDefaults
if plugin then
	for _, instance in plugin:GetDescendants() do
		if instance:HasTag("TextDefaults") then
			userDefaults = require(instance)
			break
		end
	end
else
	userDefaults = CollectionService:GetTagged("TextDefaults")[1]
	if userDefaults then userDefaults = require(userDefaults) end
end
if userDefaults and type(userDefaults) == "table" then
	for key in userDefaults do
		if optionsList[key] then defaults[key] = userDefaults[key] end
	end
end

-- Remove false booleans.
for key, value in defaults do
	if value == false then defaults[key] = nil end
end

-- Return final defaults.
return defaults