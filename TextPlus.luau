--!optimize 2
--!native

--[[

          TTTTTTTTTTTT                                                                              
TTTTTTTTTTTTTTTTTTTTTT                                                                              
TTTTTTTTTTTTTTTTTTTTTT                                                                              
 TT      TTTTT                                                      ttttt                           
         TTTTTT                                            xxx      tttttt                          
         TTTTTT            eeeeeeeeee      xxxxxxx     xxxxxx       tttttt             +++++        
         TTTTTT          eeeeeeeeeeeeee      xxxxxx    xxxxx     ttttttttttttt          +++++       
         TTTTTT         eeeeeee   eeeeee      xxxxxx  xxxxx      ttttttttttttt          +++++       
         TTTTTT        eeeeee       eeeee      xxxxxxxxxxx          tttttt              +++++++++++
         TTTTTT        eeeeeeeeeeeeeeeeee       xxxxxxxxxx          tttttt       +++++++++++++++++++
         TTTTTT       eeeeeeeeeeeeeeeeeee        xxxxxxxxx          tttttt       +++++++++++++++++++
          TTTTTT       eeeee           ee       xxxxxxxxxxx         tttttt        +++   +++++       
          TTTTTT       eeeeee                   xxxxx xxxxxx       tttttt                +++++      
          TTTTTT        eeeeee    eeeeeee      xxxxx   xxxxxxx     tttttt                +++++      
          TTTTTT         eeeeeeeeeeeeeee      xxxxxx     xxxxxx    ttttttttt             +++++      
                           eeeeeeeeee        xxxxxx                 ttttttttt                       
                                                                      ttttttt                       

A lightweight, open-source text rendering module for Roblox,
featuring custom fonts and fine-control over all characters.


GitHub:
https://github.com/AlexanderLindholt/TextPlus

Devforum:
https://devforum.roblox.com/t/text%EF%BD%9Ccustom-fonts-fine-control/3521684


--------------------------------------------------------------------------------
MIT License

Copyright (c) 2025 Alexander Lindholt

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--------------------------------------------------------------------------------

]]--

local TextService = game:GetService("TextService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local customFonts = require(script.CustomFonts)

-- Defaults.
local defaultSize = 14
local defaultColor = Color3.new(0, 0, 0)
local defaultTransparency = 0
local defaultRotation = 0
local defaultOffset = Vector2.zero
local defaultStrokeSize = 1
local defaultStrokeColor = Color3.new(0, 0, 0)
local defaultFont = Font.new("rbxasset://fonts/families/SourceSansPro.json")
local defaultLineHeight = 1
local defaultCharacterSpacing = 1
local defaultXAlignment = "Left"
local defaultYAlignment = "Top"
local defaultWordSorting = false
local defaultLineSorting = false

-- Lists for validity checks.
local customizationOptions = {
	Size = true,
	Font = true,
	Color = true,
	Transparency = true,
	Rotation = true,
	Offset = true,
	StrokeSize = true,
	StrokeColor = true,
	LineHeight = true,
	CharacterSpacing = true,
	XAlignment = true,
	YAlignment = true,
	WordSorting = true,
	LineSorting = true,
	Dynamic = true
}

local xAlignments = {
	Left = true,
	Center = true,
	Right = true
}
local yAlignments = {
	Top = true,
	Center = true,
	Bottom = true
}

-- Frame data tables.
local frameCustomizations = setmetatable({}, {__mode = "k"})
local frameTextBounds = setmetatable({}, {__mode = "k"})
local frameResizeConnections = setmetatable({}, {__mode = "k"}) -- For dynamic feature.

-- Built-in font rendering stuff.
local textBoundsParams = Instance.new("GetTextBoundsParams")
textBoundsParams.Size = 100 -- Size limit for Roblox built-in font rendering.
local characterWidthCache = {}

-- Verify and preload custom fonts if any.
if next(customFonts) then
	local screenGui = nil
	local loading = nil
	local load = nil
	if player then -- If client.
		screenGui = Instance.new("ScreenGui")
		screenGui.Parent = player.PlayerGui

		loading = 0
		load = function(image) -- For preloading the font image assets.
			local label = Instance.new("ImageLabel")
			label.Size = UDim2.fromOffset(1, 1)
			label.BackgroundTransparency = 1
			label.ImageTransparency = 0.999
			label.ResampleMode = Enum.ResamplerMode.Pixelated
			label.Image = "rbxassetid://"..tostring(image)
			label.Parent = screenGui
			coroutine.resume(coroutine.create(function()
				repeat
					task.wait()
				until label.IsLoaded == true
				
				if loading == 1 then
					screenGui:Destroy()
				else
					loading -= 1
				end
			end))
		end
	end
	local function charactersValid(characters) -- Function to verify the format of the characters in a font.
		for key, value in pairs(characters) do
			if type(key) ~= "string" then return end
			if type(value) ~= "table" then return end
			if typeof(value[1]) ~= "Vector2" then return end
			if typeof(value[2]) ~= "Vector2" then return end
			if typeof(value[3]) ~= "Vector2" then return end
			if type(value[4]) ~= "number" then return end
		end
		return true
	end
	local validWeights = {
		Thin = true,
		ExtraLight = true,
		Light = true,
		Regular = true,
		Medium = true,
		SemiBold = true,
		Bold = true,
		ExtraBold = true,
		Heavy = true
	}
	local validStyles = {
		Normal = true,
		Italic = true
	}
	for fontName, font in customFonts do
		-- Font.
		if type(fontName) ~= "string" then
			warn("A custom font has an invalid name.")
			customFonts[fontName] = nil
			continue
		end
		if type(font) ~= "table" then
			warn("Missing table for custom font '"..fontName.."'.")
			customFonts[fontName] = nil
			continue
		end
		for weightName, weight in pairs(font) do
			-- Weight.
			if not validWeights[weightName] then
				warn("Custom font '"..fontName.."' has an invalid weight.")
				font[weightName] = nil
				continue
			end
			if type(font) ~= "table" then
				warn("Missing table for the '"..weightName.."' weight in custom font '"..fontName.."'.")
				font[weightName] = nil
				continue
			end
			for styleName, style in pairs(weight) do
				-- Style.
				if not validStyles[styleName] then
					warn("The '"..weightName.."' weight for custom font '"..fontName.."' has an invalid style.")
					weight[styleName] = nil
					continue
				end
				if type(font) ~= "table" then
					warn("Missing table for the '"..styleName.."' style in the '"..weightName.."' weight for custom font '"..fontName.."'.")
					weight[styleName] = nil
					continue
				end
				if type(style.Image) ~= "number" then
					warn("Missing an image id for the '"..styleName.."' style in the '"..weightName.."' weight for custom font '"..fontName.."'.")
					weight[styleName] = nil
					continue
				end
				if type(style.Size) ~= "number" then
					warn("Missing a size for the '"..styleName.."' style in the '"..weightName.."' weight for custom font '"..fontName.."'.")
					weight[styleName] = nil
					continue
				end
				if type(style.Characters) ~= "table" then
					warn("Missing characters for the '"..styleName.."' style in the '"..weightName.."' weight for custom font '"..fontName.."'.")
					weight[styleName] = nil
					continue
				end
				if not charactersValid(style.Characters) then
					warn("Invalid characters for the '"..styleName.."' style in the '"..weightName.."' weight for custom font '"..fontName.."'.")
					weight[styleName] = nil
					continue
				end
				
				-- Passed all checks, so preload it.
				if player then -- If client.
					loading += 1
					load(style.Image)
				end
			end
		end
	end
end

-- Types.
type Customization = {
	Size: number,
	Font: Font,
	Color: Color3,
	Transparency: number,
	Rotation: number,
	Offset: Vector2,
	StrokeSize: number,
	StrokeColor: Color3,
	LineHeight: number,
	CharacterSpacing: number,
	XAlignment: "Left" | "Center" | "Right",
	YAlignment: "Top" | "Center" | "Bottom",
	WordSorting: boolean,
	LineSorting: boolean,
	Dynamic: boolean
}
type Module = {
	Create: (frame: Frame, text: string, customization: Customization?) -> (),
	
	GetTextBounds: (frame: Frame) -> Vector2,
	GetCharacters: (frame: Frame) -> {TextLabel | ImageLabel}
}

-- Module.
local module = {}

module.GetTextBounds = function(frame)
	-- Argument errors.
	if typeof(frame) ~= "Instance" or not frame:IsA("Frame") then error("No frame received.") end
	
	-- Get and verify text bounds.
	local textBounds = frameTextBounds[frame]
	if not textBounds then error("No text has been created inside this frame.") end
	
	-- Return text bounds.
	return textBounds
end
module.GetCharacters = function(frame)
	-- Argument errors.
	if typeof(frame) ~= "Instance" or not frame:IsA("Frame") then error("No frame received.") end
	
	-- Gather and return characters.
	local characters = {}
	for index = 1, #frame:GetChildren(), 1 do
		local instance = frame[tostring(index)]
		if instance:IsA("TextLabel") or instance:IsA("ImageLabel") then
			table.insert(characters, instance)
		else
			-- Line or word folder.
			for index = 1, #instance:GetChildren(), 1 do
				local inst = instance[tostring(index)]
				if inst:IsA("TextLabel") or inst:IsA("ImageLabel") then
					table.insert(characters, inst)
				else
					-- Word folder.
					for index = 1, #inst:GetChildren(), 1 do
						table.insert(characters, inst[tostring(index)])
					end
				end
			end
		end
	end
	return characters
end

local function create(frame, text, customization)
	-- Clear previous characters and any content, that may interfere.
	frame:ClearAllChildren()
	
	-- Customization references.
	local font = customization.Font
	local size = customization.Size
	local color = customization.Color
	local transparency = customization.Transparency
	local rotation = customization.Rotation
	local localOffset = customization.Offset
	local strokeSize = customization.StrokeSize
	local strokeColor = customization.StrokeColor
	local lineHeight = customization.LineHeight*size -- Multiply by size to get it from scale to pixels.
	local characterSpacing = customization.CharacterSpacing
	local xAlignment = customization.XAlignment
	local yAlignment = customization.YAlignment
	local wordSorting = customization.WordSorting
	local lineSorting = customization.LineSorting
	
	-- Setup character functions.
	local getCharacterWidth = nil
	local createCharacter = nil
	do
		local customFont = customFonts[font.Family]
		if customFont == nil then
			-- Setup Roblox font character functions.
			getCharacterWidth = function(character)
				local fontKey = character..font.Family..tostring(font.Weight.Value)..tostring(font.Style.Value)
				local width = characterWidthCache[fontKey]
				if not width then
					textBoundsParams.Text = character
					textBoundsParams.Font = font
					width = TextService:GetTextBoundsAsync(textBoundsParams).X
					characterWidthCache[fontKey] = width
					return width*0.01*size
				else
					return width*0.01*size
				end
			end
			createCharacter = function(character, width, position)
				-- Create and stylize.
				local textLabel = Instance.new("TextLabel")
				textLabel.BackgroundTransparency = 1
				textLabel.Text = character
				textLabel.TextSize = size
				textLabel.TextColor3 = color
				textLabel.TextTransparency = transparency
				textLabel.FontFace = font
				textLabel.TextXAlignment = Enum.TextXAlignment.Left
				textLabel.TextYAlignment = yAlignment
				textLabel.Size = UDim2.fromOffset(width, size)
				textLabel.Rotation = rotation
				textLabel.Position = position + localOffset
				-- Apply stroke if any is given.
				if strokeSize then
					local uiStroke = Instance.new("UIStroke")
					uiStroke.Thickness = strokeSize
					uiStroke.Color = strokeColor
					uiStroke.Parent = textLabel
				end
				-- Return character instance.
				return textLabel
			end
		else
			-- Get and verify the weight and style.
			customFont = customFont[font.Weight.Name]
			if customFont == nil then error("Font weight could not be found.") end
			customFont = customFont[font.Style.Name]
			if customFont == nil then error("Font style could not be found.") end
			
			-- Setup custom font character functions.
			local image = "rbxassetid://"..tostring(customFont.Image)
			local invertedFontSize = 1/customFont.Size -- To save on expensive division.
			local characters = customFont.Characters
			--[[
			Character data:
			  [1] = Vector2 - Size
			  [2] = Vector2 - Image offset
			  [3] = Vector2 - Offset
			  [4] = number - X advance
			]]--
			getCharacterWidth = function(character)
				return characters[character][4]*invertedFontSize*size
			end
			createCharacter = function(character, width, position)
				-- Create and stylize.
				local data = characters[character]
				local imageLabel = Instance.new("ImageLabel")
				imageLabel.BackgroundTransparency = 1
				imageLabel.Image = image
				imageLabel.ImageColor3 = color
				imageLabel.ImageTransparency = transparency
				-- Image cutout.
				local characterSize = data[1]
				imageLabel.ImageRectSize = characterSize
				imageLabel.ImageRectOffset = data[2]
				-- Transformation.
				imageLabel.Size = UDim2.fromOffset(characterSize.X*invertedFontSize*size, characterSize.Y*invertedFontSize*size)
				local offset = data[3]*invertedFontSize*size
				imageLabel.Position = position + UDim2.fromOffset(offset.X, offset.Y) + localOffset
				imageLabel.Rotation = rotation
				-- Return character instance.
				return imageLabel
			end
		end
	end
	
	-- Calculate base information.
	local textWidth = 0
	
	local frameSize = frame.AbsoluteSize
	local frameWidth = frameSize.X
	
	local spaceWidth = getCharacterWidth(" ")*characterSpacing
	
	local linesFromText = text:split("\n")
	local lines = {}
	local currentLine = {{}, 0}
	
	for _, line in linesFromText do
		if line == "" then -- Empty lines come from manual line breaks.
			if #currentLine[1] > 0 then
				textWidth = math.max(textWidth, currentLine[2])
				table.insert(lines, currentLine)
				currentLine = {{}, 0}
			end
			table.insert(lines, {{}, 0})
		else
			-- Process each word in the line.
			for word in line:gmatch("%S+") do
				-- Calculate word width.
				local wordCharacters = {}
				local wordWidth = 0
				if word == "" then -- Empty words come from consecutive spaces.
					wordWidth = spaceWidth
					wordCharacters = {{" ", spaceWidth}}
				else
					for index = 1, #word, 1 do
						local character = word:sub(index, index)
						local characterWidth = getCharacterWidth(character)*characterSpacing
						table.insert(wordCharacters, {character, characterWidth})
						wordWidth += characterWidth
					end
				end
				
				-- Line wrapping.
				local potentialWidth = nil
				if #currentLine[1] > 0 then
					potentialWidth = currentLine[2] + spaceWidth + wordWidth
				else
					potentialWidth = currentLine[2] + wordWidth
				end
				
				if potentialWidth > frameWidth then
					if #currentLine[1] > 0 then
						textWidth = math.max(textWidth, currentLine[2])
						table.insert(lines, currentLine)
						currentLine = {{}, 0}
					end
					currentLine[2] = wordWidth
					table.insert(currentLine[1], {wordCharacters, wordWidth})
				else
					currentLine[2] = potentialWidth
					table.insert(currentLine[1], {wordCharacters, wordWidth})
				end
			end
			
			-- Line break.
			if #currentLine[1] > 0 then
				textWidth = math.max(textWidth, currentLine[2])
				table.insert(lines, currentLine)
				currentLine = {{}, 0}
			end
		end
	end
	
	-- Calculate final information and render.
	local textHeight = #lines*lineHeight
	local y = nil
	if yAlignment == "Center" then
		y = math.round((frameSize.Y - textHeight)/2)
	elseif yAlignment == "Bottom" then
		y = frameSize.Y - textHeight
	else
		-- Top alignment.
		y = 0
	end
	
	local invertedCharacterSpacing = 1/characterSpacing -- To save on expensive division.
	
	local globalWordCount = 0 -- In case only word sorting is enabled.
	local globalCharacterCount = 0 -- In case no sorting is enabled.
	
	for lineIndex, line in lines do
		local lineWidth = line[2]
		local x = nil
		if xAlignment == "Center" then
			x = math.round((frameWidth - lineWidth)/2)
		elseif xAlignment == "Right" then
			x = frameWidth - lineWidth
		else
			-- Left alignment.
			x = 0
		end
		
		-- Line sorting.
		local lineContainer = frame
		if lineSorting then
			lineContainer = Instance.new("Folder")
			lineContainer.Name = tostring(lineIndex)
			lineContainer.Parent = frame
		end
		
		-- Create words.
		for wordIndex, word in line[1] do
			local wordContainer = lineContainer
			
			-- Word sorting.
			if wordSorting then
				wordContainer = Instance.new("Folder")
				-- Numerical naming.
				if lineSorting then
					wordContainer.Name = tostring(wordIndex)
				else
					globalWordCount += 1
					wordContainer.Name = tostring(globalWordCount)
				end
				-- Parent it.
				wordContainer.Parent = lineContainer
			end
			
			-- Create characters.
			for characterIndex, character in word[1] do
				local width = character[2]
				
				local element = createCharacter(character[1], width*invertedCharacterSpacing, UDim2.fromOffset(x, y))
				-- Numerical naming.
				if not lineSorting and not wordSorting then
					globalCharacterCount += 1
					element.Name = tostring(globalCharacterCount)
				else
					element.Name = tostring(characterIndex)
				end
				-- Parent it.
				element.Parent = wordContainer
				
				-- Increment x position for next character.
				x += width
			end
			
			-- Add space (space character) before the next word.
			x += spaceWidth
		end
		
		-- Add space (line height) before the next line.
		y += lineHeight
	end
	
	-- Save text bounds.
	frameTextBounds[frame] = Vector2.new(textWidth, textHeight)
end
local function handleCustomization(frame, text, customization)
	if not next(customization) then
		-- Apply defaults.
		customization.Font = defaultFont
		customization.Size = defaultSize
		customization.Color = defaultColor
		customization.Transparency = defaultTransparency
		customization.Rotation = defaultRotation
		customization.Offset = defaultOffset
		customization.LineHeight = defaultLineHeight
		customization.CharacterSpacing = defaultCharacterSpacing
		customization.XAlignment = defaultXAlignment
		customization.YAlignment = defaultYAlignment
	else
		-- Correct customizations.
		if typeof(customization.Font) ~= "Font" then
			customization.Font = defaultFont
		end
		if type(customization.Size) ~= "number" then
			customization.Size = defaultSize
		elseif customization.Size < 1 then
			customization.Size = 1
		end
		if type(customization.LineHeight) ~= "number" then
			customization.LineHeight = defaultLineHeight
		elseif customization.LineHeight < 0 then
			customization.LineHeight = 0
		elseif customization.LineHeight > 3 then
			customization.LineHeight = 3
		end
		if type(customization.CharacterSpacing) ~= "number" then
			customization.CharacterSpacing = defaultCharacterSpacing
		elseif customization.CharacterSpacing < 0 then
			customization.CharacterSpacing = 0
		elseif customization.CharacterSpacing > 3 then
			customization.CharacterSpacing = 3
		end
		if typeof(customization.Color) ~= "Color3" then
			customization.Color = defaultColor
		end
		if type(customization.Transparency) ~= "number" then
			customization.Transparency = defaultTransparency
		end
		if type(customization.Rotation) ~= "number" then
			customization.Rotation = defaultRotation
		end
		if typeof(customization.Offset) ~= "Vector2" then
			customization.Offset = defaultOffset
		end
		
		if type(customization.StrokeSize) ~= "number" then
			if typeof(customization.StrokeColor) == "Color3" then
				customization.StrokeSize = defaultStrokeSize
			else
				customization.StrokeSize = nil
				customization.StrokeColor = nil
			end
		elseif customization.StrokeSize <= 0 then
			customization.StrokeSize = nil
			customization.StrokeColor = nil
		else
			if typeof(customization.StrokeColor) == "Color3" then
				customization.StrokeSize = defaultStrokeSize
			else
				customization.StrokeSize = nil
				customization.StrokeColor = nil
			end
		end
		
		if not xAlignments[customization.XAlignment] then
			customization.XAlignment = defaultXAlignment
		end
		if not yAlignments[customization.YAlignment] then
			customization.YAlignment = defaultYAlignment
		end
		if type(customization.WordSorting) ~= "boolean" or not customization.WordSorting then
			customization.WordSorting = nil
		end
		if type(customization.LineSorting) ~= "boolean" or not customization.LineSorting then
			customization.LineSorting = nil
		end
		
		-- Dynamic feature.
		if customization.Dynamic == true then
			if not frameResizeConnections[frame] then
				frameResizeConnections[frame] = frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
					create(frame, text, customization)
				end)
			end
		elseif customization.Dynamic == false then
			local connection = frameResizeConnections[frame]
			if connection then
				connection:Disconnect()
				frameResizeConnections[frame] = nil
			end
		end
		customization.Dynamic = nil
	end
end
module.Create = function(frame, text, customization)
	-- Argument errors.
	if not text then error("No text received.") end
	if text == "" then error("Use 'frame:ClearAllChildren()' instead, if you want to clear the text.") end
	if typeof(frame) ~= "Instance" or not frame:IsA("Frame") then error("No frame received.") end
	
	-- Handle customization.
	if frameCustomizations[frame] then
		if type(customization) == "table" then
			-- Merge customizations.
			local newCustomization = customization
			customization = frameCustomizations[frame]
			for key, value in pairs(newCustomization) do
				if customizationOptions[key] then
					if value == false then
						customization[key] = nil
					else
						customization[key] = value
					end
				else
					warn('No customization option called "'..key..'".')
				end
			end
			-- Handle new (merged) customization.
			handleCustomization(frame, text, customization)
		else
			customization = frameCustomizations[frame]
		end
	else
		-- Ensure the customization is a table.
		if type(customization) ~= "table" then
			customization = {}
		end
		-- Remove invalid customizations.
		for key in pairs(customization) do
			if not customizationOptions[key] then
				customization[key] = nil
				warn('No customization option called "'..key..'".')
			end
		end
		-- Correct invalid customizations.
		handleCustomization(frame, text, customization)
	end
	
	-- Save customization.
	frameCustomizations[frame] = customization
	
	-- Create the text.
	create(frame, text, customization)
end

return table.freeze(module) :: Module
