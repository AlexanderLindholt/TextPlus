--!optimize 2
--!native

--[[
Handles the processing, validation, and preloading of custom fonts.
]]--

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local FontManager = {}
FontManager.RawFonts = {}
FontManager.MissingCharacter = "rbxassetid://75989824347198"

function FontManager.Initialize()
	local fonts = CollectionService:GetTagged("Fonts")[1]
	if not fonts then return end

	fonts = require(fonts)

	if type(fonts) ~= "table" then
		warn("Font data is not a table.")
		return
	end

	if not next(fonts) then
		warn("Font data table is empty.")
		return
	end

	local player = Players.LocalPlayer
	local load = nil
	
	if player then
		local screenGui = Instance.new("ScreenGui")
		screenGui.Name = "TextPlusFontLoader"
		screenGui.Parent = player:FindFirstChildOfClass("PlayerGui")

		local loading = 0
		load = function(image)
			loading += 1

			local label = Instance.new("ImageLabel")
			label.Size = UDim2.fromOffset(1, 1)
			label.BackgroundTransparency = 1
			label.ImageTransparency = 0.999
			label.ResampleMode = Enum.ResamplerMode.Pixelated
			label.Image = "rbxassetid://" .. tostring(image)
			label.Parent = screenGui

			task.spawn(function()
				while not label.IsLoaded do
					task.wait()
				end
				
				loading -= 1
				
				if loading == 0 then
					screenGui:Destroy()
				end
			end)
		end
	end

	local function handleCharacters(characters, size)
		local invertedFontSize = 1 / size
		
		for key, value in characters do
			if type(key) ~= "string" or type(value) ~= "table" or type(value[1]) ~= "number" or type(value[2]) ~= "number" or typeof(value[3]) ~= "Vector2" or type(value[4]) ~= "number" or type(value[5]) ~= "number" or type(value[6]) ~= "number" then
				return false
			end
			
			value[4] *= invertedFontSize
			value[5] *= invertedFontSize
			value[6] *= invertedFontSize
		end
		
		return true
	end

	local function processFonts(parent, parentPath)
		local remove = {}
		local freeze = {}
		
		for key, value in parent do
			if type(value) ~= "table" then
				table.insert(remove, key)
			else
				local currentPath = parentPath .. "." .. key
				
				if value.Image or value.Size or value.Characters then
					if type(value.Image) ~= "number" or type(value.Size) ~= "number" or type(value.Characters) ~= "table" or not handleCharacters(value.Characters, value.Size) then
						warn("Invalid font data at '" .. currentPath .. "'.")
						table.insert(remove, key)
					else
						table.insert(freeze, key)
						FontManager.RawFonts[value] = true
						
						if player then
							load(value.Image)
						end
					end
				else
					processFonts(value, currentPath)
					table.freeze(value)
				end
			end
		end
		
		for _, key in remove do
			parent[key] = nil
		end
		
		for _, key in freeze do
			table.freeze(parent[key])
		end
	end

	processFonts(fonts, "Fonts")
	table.freeze(fonts)
end

return table.freeze(FontManager)