--!optimize 2
--!native

--[[
Manages all configuration and option-related logic, including
default values, validation, and correction.
]]--

local CollectionService = game:GetService("CollectionService")
local TextService = game:GetService("TextService")

local Options = {}

Options.List = {
	Font = true,
	Size = true,
	ScaleSize = true,
	MinimumSize = true,
	MaximumSize = true,
	Color = true,
	Transparency = true,
	Pixelated = true,
	Offset = true,
	Rotation = true,
	StrokeSize = true,
	StrokeColor = true,
	StrokeTransparency = true,
	ShadowOffset = true,
	ShadowColor = true,
	ShadowTransparency = true,
	LineHeight = true,
	CharacterSpacing = true,
	Truncate = true,
	XAlignment = true,
	YAlignment = true,
	WordSorting = true,
	LineSorting = true,
	Dynamic = true,
}

local scaleSizeTypes = {
	RootX = true,
	RootY = true,
	RootXY = true,
	FrameX = true,
	FrameY = true,
	FrameXY = true,
}

local xAlignments = {
	Left = true,
	Center = true,
	Right = true,
	Justified = true,
}
local yAlignments = {
	Top = true,
	Center = true,
	Bottom = true,
	Justified = true,
}

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
	Dynamic = false,
}

local userDefaults = CollectionService:GetTagged("TextDefaults")[1]

if userDefaults then
	userDefaults = require(userDefaults)
	
	if type(userDefaults) == "table" then
		for key, value in userDefaults do
			if Options.List[key] then
				defaults[key] = value
			end
		end
	end
end

for key, value in defaults do
	if value == false then
		defaults[key] = nil
	end
end

Options.Defaults = table.freeze(defaults)

function Options.Correct(options, rawFonts, textBoundsParams)
	if not scaleSizeTypes[options.ScaleSize] then
		options.ScaleSize = defaults.ScaleSize
	end
	
	if not scaleSizeTypes[options.ScaleSize] then
		options.ScaleSize = nil
		options.MinimumSize = nil
		options.MaximumSize = nil

		if type(options.Size) ~= "number" then
			options.Size = defaults.Size
		elseif options.Size < 1 then
			options.Size = 1
		end
	else
		if type(options.MinimumSize) ~= "number" then
			options.MinimumSize = defaults.MinimumSize
		end
		
		if type(options.MinimumSize) ~= "number" then
			options.MinimumSize = nil
		elseif options.MinimumSize < 1 then
			options.MinimumSize = 1
		end

		if type(options.MaximumSize) ~= "number" then
			options.MaximumSize = defaults.MaximumSize
		end
		
		if type(options.MaximumSize) ~= "number" then
			options.MaximumSize = nil
		elseif options.MaximumSize < 1 then
			options.MaximumSize = 1
		end

		if type(options.Size) ~= "number" then
			options.Size = defaults.Size
		end
	end

	local font = options.Font
	if font == nil then
		options.Font = defaults.Font
		textBoundsParams.Font = defaults.Font

		if options.Size > 100 then
			options.Size = 100
		end
	elseif typeof(font) == "Font" then 
		textBoundsParams.Font = options.Font
		textBoundsParams.Text = " "
		
		local _, result = pcall(TextService.GetTextBoundsAsync, TextService, textBoundsParams)
		if type(result) == "string" then
			warn("Invalid font. Fallback to default.")
			options.Font = defaults.Font
			textBoundsParams.Font = defaults.Font
		end

		if options.Size > 100 then
			options.Size = 100
		end
	else
		if not rawFonts[font] then
			warn("Invalid font. Fallback to default.")

			options.Font = defaults.Font
			textBoundsParams.Font = defaults.Font

			if options.Size > 100 then
				options.Size = 100
			end
		end
	end

	local lineHeight = options.LineHeight
	if type(lineHeight) ~= "number" then
		options.LineHeight = defaults.LineHeight
	elseif lineHeight < 0 then
		options.LineHeight = 0
	end
	
	local characterSpacing = options.CharacterSpacing
	if type(characterSpacing) ~= "number" then
		options.CharacterSpacing = defaults.CharacterSpacing
	elseif characterSpacing < 0 then
		options.CharacterSpacing = 0
	end

	if typeof(options.Color) ~= "Color3" then
		options.Color = defaults.Color
	end
	
	if type(options.Transparency) ~= "number" then
		options.Transparency = defaults.Transparency
	end

	local pixelated = options.Pixelated
	if pixelated == false then
		options.Pixelated = nil
	elseif pixelated ~= true then
		options.Pixelated = defaults.Pixelated
	end

	if typeof(options.Offset) ~= "Vector2" then
		options.Offset = defaults.Offset
	end
	if type(options.Rotation) ~= "number" then
		options.Rotation = defaults.Rotation
	end

	local strokeSize = options.StrokeSize
	local strokeColor = options.StrokeColor
	local strokeTransparency = options.StrokeTransparency
	
	if type(strokeSize) ~= "number" then
		if typeof(strokeColor) == "Color3" then
			options.StrokeSize = defaults.StrokeSize
			
			if type(strokeTransparency) ~= "number" then
				options.StrokeTransparency = options.Transparency
			end
		elseif type(strokeTransparency) == "number" then
			options.StrokeSize = defaults.StrokeSize
			
			if type(strokeColor) ~= "number" then
				options.StrokeColor = defaults.StrokeColor
			end
		else
			options.StrokeSize = nil
			options.StrokeColor = nil
			options.StrokeTransparency = nil
		end
	else
		if strokeSize < 1 then
			options.StrokeSize = 1
		end
		
		if typeof(strokeColor) ~= "Color3" then
			options.StrokeColor = defaults.StrokeColor
		end
		
		if type(strokeTransparency) ~= "number" then
			options.StrokeTransparency = options.Transparency
		end
	end

	local shadowOffset = options.ShadowOffset
	local shadowColor = options.ShadowColor
	local shadowTransparency = options.ShadowTransparency
	
	if typeof(shadowOffset) ~= "Vector2" then
		if typeof(shadowColor) == "Color3" then
			options.ShadowOffset = defaults.ShadowOffset
			
			if type(shadowTransparency) ~= "number" then
				options.ShadowTransparency = options.Transparency
			end
		elseif type(shadowTransparency) == "number" then
			options.ShadowOffset = defaults.ShadowOffset
			
			if type(shadowColor) ~= "number" then
				options.ShadowColor = defaults.ShadowColor
			end
		else
			options.ShadowOffset = nil
			options.ShadowColor = nil
			options.ShadowTransparency = nil
		end
	else
		if typeof(shadowColor) ~= "Color3" then
			options.ShadowColor = defaults.ShadowColor
		end
		
		if type(shadowTransparency) ~= "number" then
			options.ShadowTransparency = options.Transparency
		end
	end

	local truncate = options.Truncate
	if truncate == false then
		options.Truncate = nil
	elseif truncate ~= true then
		options.Truncate = defaults.Truncate
	end

	if not xAlignments[options.XAlignment] then
		options.XAlignment = defaults.XAlignment
	end
	
	if not yAlignments[options.YAlignment] then
		options.YAlignment = defaults.YAlignment
	end

	local wordSorting = options.WordSorting
	if wordSorting == false then
		options.WordSorting = nil
	elseif wordSorting ~= true then
		options.WordSorting = defaults.WordSorting
	end

	local lineSorting = options.LineSorting
	if lineSorting == false then
		options.LineSorting = nil
	elseif lineSorting ~= true then
		options.LineSorting = defaults.LineSorting
	end
end

return table.freeze(Options)