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

v1.5.0

A lightweight, open-source text rendering module for Roblox,
featuring custom fonts and fine-control over all characters.


GitHub:
https://github.com/AlexanderLindholt/TextPlus

Devforum:
https://devforum.roblox.com/t/3521684


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

local customFonts = require(script.CustomFonts)

-- Defaults.
local defaultSize = 14
local defaultColor = Color3.new(0, 0, 0)
local defaultTransparency = 0
local defaultRotation = 0
local defaultOffset = UDim2.fromOffset(0, 0)
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
	Right = true,
	Justified = true
}
local yAlignments = {
	Top = true,
	Center = true,
	Bottom = true,
	Justified = true
}

-- Frame data tables.
local frameCustomizations = setmetatable({}, {__mode = "k"})
local frameTextBounds = setmetatable({}, {__mode = "k"})
local frameResizeConnections = setmetatable({}, {__mode = "k"}) -- For dynamic feature.

-- Built-in font rendering stuff.
local textBoundsParams = Instance.new("GetTextBoundsParams")
textBoundsParams.Size = 100 -- Size limit for Roblox built-in font rendering.
local characterWidthCache = {}

-- Create a raw custom fonts table.
local rawCustomFonts = {}

-- Verify and preload custom fonts if any.
if next(customFonts) then
	local player = Players.LocalPlayer
	local screenGui = nil
	local loading = nil
	local load = nil
	if player then -- If running on client.
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
	local function handleCharacters(characters, size)
		local invertedFontSize = 1/size -- To avoid expensive division.
		
		for key, value in characters do
			-- Verify format.
			if type(key) ~= "string" then return end
			if #key ~= 1 then return end
			if type(value) ~= "table" then return end
			if type(value[1]) ~= "number" then return end
			if type(value[2]) ~= "number" then return end
			if typeof(value[3]) ~= "Vector2" then return end
			if type(value[4]) ~= "number" then return end
			if type(value[5]) ~= "number" then return end
			if type(value[6]) ~= "number" then return end
			
			-- Precalculate normalized offset and x advance.
			value[4] *= invertedFontSize
			value[5] *= invertedFontSize
			value[6] *= invertedFontSize
		end
		
		return true
	end
	local function processFonts(parent, parentPath)
		local remove = {}
		for key, value in parent do
			if type(value) ~= "table" then
				table.insert(remove, key)
			else
				local currentPath = parentPath.."."..key
				
				if value.Image or value.Size or value.Characters then
					-- Verify format.
					if type(value.Image) ~= "number" then
						warn("Missing an image id in \""..currentPath.."\".")
						table.insert(remove, key)
						continue
					end
					if type(value.Size) ~= "number" then
						warn("Missing a size in \""..currentPath.."\".")
						table.insert(remove, key)
						continue
					end
					if type(value.Characters) ~= "table" then
						warn("Missing characters in \""..currentPath.."\".")
						table.insert(remove, key)
						continue
					end
					if not handleCharacters(value.Characters, value.Size) then
						warn("Invalid characters in \""..currentPath.."\".")
						table.insert(remove, key)
						continue
					end
					
					-- Freeze the font table.
					table.freeze(value)
					
					-- Insert the font into raw fonts table.
					rawCustomFonts[value] = true
					
					-- Preload images.
					if player then -- If running on client.
						loading += 1
						load(value.Image)
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
	end
	processFonts(customFonts, "CustomFonts")
	table.freeze(customFonts)
end

-- Types.
export type CustomFont = {
	Image: number,
	Size: number,
	Characters: {
		[string]: {}
	}
}
export type Customization = {
	Size: number,
	Font: Font | CustomFont,
	Color: Color3,
	Transparency: number,
	Rotation: number,
	Offset: UDim2,
	StrokeSize: number,
	StrokeColor: Color3,
	LineHeight: number,
	CharacterSpacing: number,
	XAlignment: "Left" | "Center" | "Right" | "Justified",
	YAlignment: "Top" | "Center" | "Bottom" | "Justified",
	WordSorting: boolean,
	LineSorting: boolean,
	Dynamic: boolean
}
type Container = Frame | ScrollingFrame | CanvasGroup

-- Module.
local module = {}

module.CustomFonts = customFonts -- Set quick access to custom fonts.

--[[
Gets the text bounds of a frame.
Requires text having been created inside the frame.
]]--
module.GetTextBounds = function(frame: Container): Vector2
	-- Argument errors.
	if typeof(frame) ~= "Instance" or not (frame:IsA("Frame") or frame:IsA("ScrollingFrame") or frame:IsA("CanvasGroup")) then error("No frame received.") end
	
	-- Get and verify text bounds.
	local textBounds = frameTextBounds[frame]
	if not textBounds then return Vector2.zero end
	
	-- Return text bounds.
	return textBounds
end
--[[
Gathers all characters from a frame into a table.
Returns only the characters and no folders.
Works with any sorting.
]]--
module.GetCharacters = function(frame: Container): {TextLabel | ImageLabel}
	-- Argument errors.
	if typeof(frame) ~= "Instance" or not (frame:IsA("Frame") or frame:IsA("ScrollingFrame") or frame:IsA("CanvasGroup")) then error("No frame received.") end
	
	-- Gather and return characters.
	local customization = frameCustomizations[frame]
	if customization == nil then return end
	
	local children = frame:GetChildren()
	if #children == 0 then return end
	
	if customization.LineSorting and customization.WordSorting then
		local characters = {}
		for _, lineFolder in children do
			for _, wordFolder in lineFolder:GetChildren() do
				for _, character in wordFolder:GetChildren() do
					table.insert(characters, character)
				end
			end
		end
		return characters
	elseif customization.LineSorting or customization.WordSorting then
		local characters = {}
		for _, folder in children do
			-- Line or word folder.
			for _, character in folder:GetChildren() do
				table.insert(characters, character)
			end
		end
		return characters
	else
		return children
	end
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
		if type(font) == "table" then -- If custom font.
			-- Setup custom font character functions.
			local image = "rbxassetid://"..tostring(font.Image)
			local invertedFontSize = 1/font.Size -- To save on expensive division.
			local characters = font.Characters
			--[[
			Character data:
			  [1] = number - Size x
			  [2] = number - Size y
			  [3] = Vector2 - Image offset
			  [4] = number - Offset x
			  [5] = number - Offset y
			  [6] = number - X advance
			]]--
			getCharacterWidth = function(character)
				return characters[character][6]*size
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
				local width = data[1]
				local height = data[2]
				imageLabel.ImageRectSize = Vector2.new(width, height)
				imageLabel.ImageRectOffset = data[3]
				-- Transformation.
				imageLabel.Size = UDim2.fromOffset(width*invertedFontSize*size, height*invertedFontSize*size)
				imageLabel.Position = position + UDim2.fromOffset(data[4]*size, data[5]*size) + localOffset
				imageLabel.Rotation = rotation
				-- Return character Instance.new.
				return imageLabel
			end
		else
			-- Setup Roblox font character functions.
			getCharacterWidth = function(character)
				local fontKey = character..font.Family..tostring(font.Weight.Value)..tostring(font.Style.Value)
				local width = characterWidthCache[fontKey]
				if not width then
					textBoundsParams.Text = character
					width = TextService:GetTextBoundsAsync(textBoundsParams).X*0.01
					characterWidthCache[fontKey] = width
					return width*size
				else
					return width*size
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
				textLabel.TextYAlignment = Enum.TextYAlignment.Top
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
		end
	end
	
	-- Calculate base information.
	local textWidth = 0
	
	local frameSize = frame.AbsoluteSize
	local frameWidth = frameSize.X
	
	local spaceWidth = getCharacterWidth(" ")*characterSpacing
	
	local lines = {}
	local currentLine = {{}, 0}
	
	for _, line in text:split("\n") do
		if line == "" then -- Empty lines come from consecutive manual line breaks.
			if #currentLine[1] > 0 then
				local width = currentLine[2]
				if width > textWidth then
					textWidth = width
				end
				table.insert(lines, currentLine)
				currentLine = {{}, 0}
			end
			table.insert(lines, {{}, 0})
		else
			-- Process each word in the line.
			for _, word in line:split(" ") do
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
						local width = currentLine[2]
						if width > textWidth then
							textWidth = width
						end
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
				local width = currentLine[2]
				if width > textWidth then
					textWidth = width
				end
				table.insert(lines, currentLine)
				currentLine = {{}, 0}
			end
		end
	end
	
	-- Calculate final information and render.
	local textHeight = #lines*lineHeight
	local lineGap = 0
	local y = nil
	if yAlignment == "Top" then
		y = 0
	elseif yAlignment == "Center" then
		y = math.round((frameSize.Y - textHeight)/2)
	elseif yAlignment == "Bottom" then
		y = frameSize.Y - textHeight
	else
		-- Justified alignment.
		if #lines > 1 then
			lineGap = (frameSize.Y - lineHeight)/(#lines - 1)
		end
	end
	
	local invertedCharacterSpacing = 1/characterSpacing -- To avoid expensive division.
	
	local globalWordCount = 0 -- In case only word sorting is enabled.
	local globalCharacterCount = 0 -- In case no sorting is enabled.
	
	for lineIndex, line in lines do
		local words = line[1]
		local lineWidth = line[2]
		local wordGap = 0
		local x = nil
		if xAlignment == "Left" then
			x = 0
		elseif xAlignment == "Center" then
			x = math.round((frameWidth - lineWidth)/2)
		elseif xAlignment == "Right" then
			x = frameWidth - lineWidth
		else
			-- Justified alignment.
			if lineIndex ~= #lines and #words > 1 then
				wordGap = (frameWidth - lineWidth)/(#words - 1)
			end
		end
		
		-- Line sorting.
		local lineContainer = frame
		if lineSorting then
			lineContainer = Instance.new("Folder")
			lineContainer.Name = tostring(lineIndex)
			lineContainer.Parent = frame
		end
		
		-- Create words.
		for wordIndex, word in words do
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
				
				-- Add space before the next character.
				x += width
			end
			
			-- Add space before the next word.
			x += spaceWidth + wordGap
		end
		
		-- Add space before the next line.
		y += lineHeight + lineGap
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
		if typeof(customization.Font) == "Font" then
			textBoundsParams.Font = customization.Font
			textBoundsParams.Text = " "
			local _, result = pcall(function()
				return TextService:GetTextBoundsAsync(textBoundsParams)
			end)
			if type(result) == "string" then
				customization.Font = defaultFont
				textBoundsParams.Font = defaultFont
				warn("Invalid font. Switched to default.")
			end
		else
			if type(customization.Font) == "table" then
				if not rawCustomFonts[customization.Font] then
					customization.Font = defaultFont
					textBoundsParams.Font = defaultFont
					warn("Invalid font. Switched to default.")
				end
			else
				customization.Font = defaultFont
				textBoundsParams.Font = defaultFont
				warn("Invalid font. Switched to default.")
			end
		end
		
		if type(customization.Size) ~= "number" then
			customization.Size = defaultSize
		elseif customization.Size < 1 then
			customization.Size = 1
		elseif customization.Size > 100 then
			customization.Size = 100
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
		if typeof(customization.Offset) ~= "UDim2" then
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
--[[
Creates text inside of a specified frame.
If text is already present, it will overwrite text and merge customizations.

<strong>frame</strong>: The container and bounding box.
]]--
module.Create = function(frame: Container, text: string, customization: Customization?)
	-- Argument errors.
	if not text then error("No text received.") end
	if text == "" then error("Use 'frame:ClearAllChildren()' instead, if you want to clear the text.") end
	if typeof(frame) ~= "Instance" or not (frame:IsA("Frame") or frame:IsA("ScrollingFrame") or frame:IsA("CanvasGroup")) then error("No frame received.") end
	
	-- Handle customization.
	if frameCustomizations[frame] then
		if type(customization) == "table" then
			-- Merge customizations.
			local newCustomization = customization
			customization = frameCustomizations[frame]
			for key, value in newCustomization do
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
		for key in customization do
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

return table.freeze(module)
