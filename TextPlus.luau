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

v1.7.0

An efficient, robust, open-source text rendering module for
Roblox, featuring custom fonts and advanced text control.


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
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

local customFonts = require(script.CustomFonts)

-- Defaults.
local defaultFont = Font.new("rbxasset://fonts/families/SourceSansPro.json")
local defaultSize = 14
local defaultColor = Color3.fromRGB(0, 0, 0)
local defaultTransparency = 0
local defaultRotation = 0
local defaultOffset = Vector2.zero

local defaultStrokeSize = 1
local defaultStrokeColor = Color3.fromRGB(0, 0, 0)

local defaultShadowOffset = Vector2.new(0, 4)
local defaultShadowColor = Color3.fromRGB(50, 50, 50)

local defaultLineHeight = 1
local defaultCharacterSpacing = 1

local defaultXAlignment = "Left"
local defaultYAlignment = "Top"

-- Lists for validity checks.
local customizationOptions = {
	Font = true,
	Size = true,
	Color = true,
	Transparency = true,
	Rotation = true,
	Offset = true,
	
	StrokeSize = true,
	StrokeColor = true,
	
	ShadowOffset = true,
	ShadowColor = true,
	
	LineHeight = true,
	CharacterSpacing = true,
	
	Truncate = true,
	
	XAlignment = true,
	YAlignment = true,
	
	WordSorting = true,
	LineSorting = true,
	
	Dynamic = true
}

local truncateTypes = {
	Clear = true,
	Cut = true
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
local frameText = {}
local frameCustomizations = {}
local frameTextBounds = {}
local frameDynamicConnections = {}
local frameSizes = {}

-- Built-in font rendering stuff.
local textBoundsParams = Instance.new("GetTextBoundsParams")
textBoundsParams.Size = 100 -- Size limit for Roblox built-in font rendering.
local characterWidthCache = {}

-- Create a raw custom fonts table.
local rawCustomFonts = {}

-- Verify and preload custom fonts if any.
if next(customFonts) then
	local player = Players.LocalPlayer
	local load = nil
	if player then -- If running on client.
		local screenGui = Instance.new("ScreenGui")
		screenGui.Parent = player.PlayerGui
		
		local loading = 0
		load = function(image) -- For preloading the font image assets.
			loading += 1
			
			local label = Instance.new("ImageLabel")
			label.Size = UDim2.fromOffset(1, 1)
			label.BackgroundTransparency = 1
			label.ImageTransparency = 0.999 -- Trick to make the image invisible and still have it be loaded.
			label.ResampleMode = Enum.ResamplerMode.Pixelated
			label.Image = "rbxassetid://"..tostring(image)
			label.Parent = screenGui
			
			coroutine.resume(coroutine.create(function()
				repeat
					task.wait()
				until label.IsLoaded
				
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
		local freeze = {}
		for key, value in parent do
			if type(value) ~= "table" then
				-- Insert for later removal.
				table.insert(remove, key)
			else
				local currentPath = parentPath.."."..key
				
				if value.Image or value.Size or value.Characters then
					-- Verify format.
					if type(value.Image) ~= "number" then
						warn("Missing an image id at '"..currentPath.."'.")
						table.insert(remove, key)
						continue
					end
					if type(value.Size) ~= "number" then
						warn("Missing a size at '"..currentPath.."'.")
						table.insert(remove, key)
						continue
					end
					if type(value.Characters) ~= "table" then
						warn("Missing characters at '"..currentPath.."'.")
						table.insert(remove, key)
						continue
					end
					if not handleCharacters(value.Characters, value.Size) then
						warn("Invalid characters at '"..currentPath.."'.")
						table.insert(remove, key)
						continue
					end
					
					-- Insert for later freeze.
					table.insert(freeze, key)
					
					-- Insert the font into raw fonts table.
					rawCustomFonts[value] = true
					
					-- Preload images.
					if player then -- If running on client.
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
		for _, key in freeze do
			table.freeze(parent[key])
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
	Font: Font | CustomFont,
	Size: number,
	Color: Color3,
	Transparency: number,
	Rotation: number,
	Offset: UDim2,
	
	StrokeSize: number,
	StrokeColor: Color3,
	
	ShadowOffset: number,
	ShadowColor: number,
	
	LineHeight: number,
	CharacterSpacing: number,
	
	Truncate: "Clear" | "Cut",
	
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
Gets the raw text string for a frame.
]]--
module.GetText = function(frame: Container): Customization
	-- Argument errors.
	if typeof(frame) ~= "Instance" or not (frame:IsA("Frame") or frame:IsA("ScrollingFrame") or frame:IsA("CanvasGroup")) then error("No frame received.") end
	
	-- Get and return text.
	return frameText[frame]
end
--[[
Gets the customization for a frame.
]]--
module.GetCustomization = function(frame: Container): Customization
	-- Argument errors.
	if typeof(frame) ~= "Instance" or not (frame:IsA("Frame") or frame:IsA("ScrollingFrame") or frame:IsA("CanvasGroup")) then error("No frame received.") end
	
	-- Get and return customization.
	return frameCustomizations[frame]
end
--[[
Gets the text bounds of a frame.
Returns <code>Vector2.zero</code> if not found.
]]--
module.GetTextBounds = function(frame: Container): Vector2
	-- Argument errors.
	if typeof(frame) ~= "Instance" or not (frame:IsA("Frame") or frame:IsA("ScrollingFrame") or frame:IsA("CanvasGroup")) then error("No frame received.") end
	
	-- Get and return text bounds
	local textBounds = frameTextBounds[frame]
	if not textBounds then return Vector2.zero end
	return textBounds
end
--[[
Gathers all characters from a frame into a table.
Returns <code>{}</code> if not found.

<em>Returns only the characters and no folders.
Works with any sorting.
Ordered numerically.</em>
]]--
module.GetCharacters = function(frame: Container): {TextLabel | ImageLabel}
	-- Argument errors.
	if typeof(frame) ~= "Instance" or not (frame:IsA("Frame") or frame:IsA("ScrollingFrame") or frame:IsA("CanvasGroup")) then error("No frame received.") end
	
	-- Get and verify customization.
	local customization = frameCustomizations[frame]
	if not customization then return {} end -- Return a blank table if frame doesn't have text inside.
	
	-- Gather and return characters.
	if customization.LineSorting and customization.WordSorting then
		-- Both sortings.
		local characters = {}
		for _, line in frame:GetChildren() do
			for _, word in line:GetChildren() do
				for _, character in word:GetChildren() do
					table.insert(characters, character)
				end
			end
		end
		return characters
	elseif customization.LineSorting or customization.WordSorting then
		-- One sorting.
		local characters = {}
		for _, folder in frame:GetChildren() do
			-- Line or word folder.
			for _, character in folder:GetChildren() do
				table.insert(characters, character)
			end
		end
		return characters
	else
		-- No sorting.
		return frame:GetChildren()
	end
end

local function calculateAbsoluteSize(instance)
	local scaleX = 1
	local scaleY = 1
	local offsetX = 0
	local offsetY = 0
	
	local rootSizeX = nil
	local rootSizeY = nil
	
	while true do
		-- Cache size values.
		local size = instance.Size
		local x = size.X
		local y = size.Y
		-- Accumulate offsets using current scale.
		offsetX = x.Offset*scaleX + offsetX
		offsetY = y.Offset*scaleY + offsetY
		-- Update scales.
		scaleX = x.Scale*scaleX
		scaleY = y.Scale*scaleY
		
		-- Traverse.
		instance = instance.Parent
		
		-- Ensure an instance.
		if not instance then return Vector2.zero end
		
		-- Check for root gui instance, and if found, calculate root size.
		if instance:IsA("ScreenGui") then
			local camera = workspace.CurrentCamera
			if not camera then return Vector2.zero end
			
			local viewportSize = camera.ViewportSize
			if instance.IgnoreGuiInset then
				rootSizeX = viewportSize.X
				rootSizeY = viewportSize.Y
			else
				local inset = GuiService:GetGuiInset()
				rootSizeX = viewportSize.X - inset.X
				rootSizeY = viewportSize.Y - inset.Y
			end
			
			break
		elseif instance:IsA("SurfaceGui") then
			local adornee = instance.Adornee
			if not adornee then
				adornee = instance.Parent
				if not adornee then return end
			end
			if not adornee:IsA("BasePart") then return end
			
			local face = instance.Face
			local pixelsPerStud = instance.PixelsPerStud
			local partSize = adornee.Size
			
			if face == Enum.NormalId.Front or face == Enum.NormalId.Back then
				rootSizeX = partSize.X*pixelsPerStud
				rootSizeY = partSize.Y*pixelsPerStud
			elseif face == Enum.NormalId.Left or face == Enum.NormalId.Right then
				rootSizeX = partSize.Z*pixelsPerStud
				rootSizeY = partSize.Y*pixelsPerStud
			else
				-- Top or bottom face.
				rootSizeX = partSize.X*pixelsPerStud
				rootSizeY = partSize.Z*pixelsPerStud
			end
			
			break
		else
			-- Verify instance.
			if not instance:IsA("GuiObject") and not instance:IsA("Folder") then break end
		end
	end
	
	-- Final calculation and return result.
	return Vector2.new(
		rootSizeX*scaleX + offsetX,
		rootSizeY*scaleY + offsetY
	)
end
local function render(frame, text, customization, frameSize)
	-- Clear previous characters and any content, that may interfere.
	frame:ClearAllChildren()
	
	-- Customization references.
	local font = customization.Font
	local size = customization.Size
	local color = customization.Color
	local transparency = customization.Transparency
	local rotation = customization.Rotation
	local offset = customization.Offset offset = UDim2.fromOffset(offset.X, offset.Y) -- Convert Vector2 to UDim2.
	
	local strokeSize = customization.StrokeSize
	local strokeColor = customization.StrokeColor
	
	local shadowOffset = customization.ShadowOffset
	local shadowColor = customization.ShadowColor
	
	local lineHeight = customization.LineHeight*size -- Multiply by size to get it from scale to pixels.
	local characterSpacing = customization.CharacterSpacing
	
	local truncate = customization.Truncate
	
	local xAlignment = customization.XAlignment
	local yAlignment = customization.YAlignment
	
	local wordSorting = customization.WordSorting
	local lineSorting = customization.LineSorting
	
	-- Setup character functions.
	local getCharacterWidth = nil
	local createCharacter = nil
	do
		if type(font) == "table" then
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
				return characters[character][6]*size*characterSpacing
			end
			if shadowOffset then
				shadowOffset = UDim2.fromOffset(shadowOffset.X, shadowOffset.Y) -- Convert Vector2 to UDim2.
				createCharacter = function(character, position)
					-- Calculate information.
					local data = characters[character]
					local width = data[1]
					local height = data[2]
					local imageSize = Vector2.new(width, height)
					local imageOffset = data[3]
					-- Shadow.
					local shadow = Instance.new("ImageLabel")
					do
						-- Stylize.
						shadow.BackgroundTransparency = 1
						shadow.Image = image
						shadow.ImageColor3 = shadowColor
						shadow.ImageTransparency = transparency
						-- Image cutout.
						shadow.ImageRectSize = imageSize
						shadow.ImageRectOffset = imageOffset
						-- Transformation.
						shadow.Size = UDim2.fromOffset(width*invertedFontSize*size, height*invertedFontSize*size)
						shadow.Position = position + UDim2.fromOffset(data[4]*size, data[5]*size) + offset + shadowOffset
						shadow.Rotation = rotation
					end
					-- Main.
					do
						-- Create and stylize.
						local main = Instance.new("ImageLabel")
						main.BackgroundTransparency = 1
						main.Image = image
						main.ImageColor3 = color
						main.ImageTransparency = transparency
						-- Image cutout.
						main.ImageRectSize = imageSize
						main.ImageRectOffset = imageOffset
						-- Transformation.
						main.Size = UDim2.fromScale(1, 1)
						main.Position = -shadowOffset -- Counteract the shadow offset.
						-- Name and parent.
						main.Name = "Main"
						main.Parent = shadow
					end
					-- Return character instance.
					return shadow
				end
			else
				createCharacter = function(character, position)
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
					imageLabel.Position = position + UDim2.fromOffset(data[4]*size, data[5]*size) + offset
					imageLabel.Rotation = rotation
					-- Return character instance.
					return imageLabel
				end
			end
		else
			-- Setup Roblox font character functions.
			local invertedCharacterSpacing = 1/characterSpacing -- To avoid expensive division.
			getCharacterWidth = function(character)
				local fontKey = character..font.Family..tostring(font.Weight.Value)..tostring(font.Style.Value)
				local width = characterWidthCache[fontKey]
				if not width then
					textBoundsParams.Text = character
					width = TextService:GetTextBoundsAsync(textBoundsParams).X*0.01
					characterWidthCache[fontKey] = width
					return width*size*characterSpacing
				else
					return width*size*characterSpacing
				end
			end
			if shadowOffset then
				shadowOffset = UDim2.fromOffset(shadowOffset.X, shadowOffset.Y) -- Convert Vector2 to UDim2.
				createCharacter = function(character, position, width)
					local shadow = Instance.new("TextLabel")
					do
						-- Stylize.
						shadow.BackgroundTransparency = 1
						shadow.Text = character
						shadow.TextSize = size
						shadow.TextColor3 = shadowColor
						shadow.TextTransparency = transparency
						shadow.FontFace = font
						shadow.TextXAlignment = Enum.TextXAlignment.Left
						shadow.TextYAlignment = Enum.TextYAlignment.Top
						-- Transformation.
						shadow.Size = UDim2.fromOffset(width*invertedCharacterSpacing, size)
						shadow.Rotation = rotation
						shadow.Position = position + offset + shadowOffset
					end
					local main = Instance.new("TextLabel")
					do
						-- Stylize.
						main.BackgroundTransparency = 1
						main.Text = character
						main.TextSize = size
						main.TextColor3 = color
						main.TextTransparency = transparency
						main.FontFace = font
						main.TextXAlignment = Enum.TextXAlignment.Left
						main.TextYAlignment = Enum.TextYAlignment.Top
						-- Transformation.
						main.Size = UDim2.fromScale(1, 1)
						main.Position = -shadowOffset -- Counteract the shadow offset.
						-- Name and parent.
						main.Name = "Main"
						main.Parent = shadow
					end
					-- Apply stroke if customization is given.
					if strokeSize then
						do
							local uiStroke = Instance.new("UIStroke")
							uiStroke.Thickness = strokeSize
							uiStroke.Color = strokeColor
							uiStroke.Parent = main
						end
						do
							local uiStroke = Instance.new("UIStroke")
							uiStroke.Thickness = strokeSize
							uiStroke.Color = strokeColor
							uiStroke.Parent = shadow
						end
					end
					-- Return character instance.
					return shadow
				end
			else
				createCharacter = function(character, position, width)
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
					-- Transformation.
					textLabel.Size = UDim2.fromOffset(width*invertedCharacterSpacing, size)
					textLabel.Rotation = rotation
					textLabel.Position = position + offset
					-- Apply stroke if customization is given.
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
	end
	
	-- Calculate base information.
	local textWidth = 0
	
	local frameWidth = frameSize.X
	local frameHeight = frameSize.Y
	
	local spaceWidth = getCharacterWidth(" ")
	
	local lines = {}
	local currentLineWords = {}
	local currentLineWidth = 0
	
	local truncated = false
	
	local rawLines = text:split("\n")
	
	for _, line in rawLines do
		if truncated then break end
		
		if line == "" then -- Empty lines come from consecutive manual line breaks.
			if #currentLineWords > 0 then
				-- Update text width.
				local width = currentLineWidth
				if width > textWidth then textWidth = width end
				
				-- Insert current line.
				table.insert(lines, {currentLineWords, currentLineWidth})
				-- Create new line.
				currentLineWords = {}
				currentLineWidth = 0
			end
			table.insert(lines, {{}, 0})
		else
			-- Process each word in the line.
			local words = line:split(" ")
			local wordWidth = 0
			for wordIndex, word in words do
				if truncated then break end
				
				local wordCharacters = {}
				if word == "" then -- Empty words come from consecutive spaces.
					currentLineWidth += spaceWidth
					table.insert(currentLineWords, wordCharacters)
				else
					-- Insert characters and calculate word width.
					for index = 1, #word, 1 do
						local character = word:sub(index, index)
						local characterWidth = getCharacterWidth(character)
						table.insert(wordCharacters, {character, characterWidth})
						wordWidth += characterWidth
					end
					
					local potentialLineWidth = currentLineWidth + wordWidth
					
					if potentialLineWidth > frameWidth then
						-- Truncate if necessary.
						if truncate and #lines*lineHeight + size > frameHeight then
							truncated = true
							
							local dotWidth = getCharacterWidth(".")
							local dot = {".", dotWidth}
							
							if truncate == "Clear" then
								-- Find last word.
								local lastLineWords = lines[#lines][1]
								local lastWord = lastLineWords[#lastLineWords]
								-- Clear word.
								table.clear(lastWord)
								-- Add ellipsis.
								table.insert(lastWord, dot)
								table.insert(lastWord, dot)
								table.insert(lastWord, dot)
							else -- "Cut" truncation.
								-- Find last word.
								local lastLine = lines[#lines]
								local lastLineWords = lastLine[1]
								local lastWord = lastLineWords[#lastLineWords]
								-- Cut off word.
								local ellipsisWidth = dotWidth*3
								local lastLineWidth = lastLine[2]
								if frameWidth - lastLineWidth < ellipsisWidth then
									for index = #lastWord, 1, -1 do
										lastLineWidth -= lastWord[index][2]
										lastWord[index] = nil
										if frameWidth - lastLineWidth >= ellipsisWidth then break end
									end
									lastLine[2] = lastLineWidth
								end
								-- Add ellipsis.
								table.insert(lastWord, dot)
								table.insert(lastWord, dot)
								table.insert(lastWord, dot)
							end
						else
							-- Line wrapping.
							if wordIndex == 1 then
								currentLineWidth = potentialLineWidth
								table.insert(currentLineWords, wordCharacters)
							else
								-- Update text width.
								local width = currentLineWidth
								if width > textWidth then textWidth = width end
								
								-- Insert current line.
								table.insert(lines, {currentLineWords, currentLineWidth})
								-- Create new line.
								currentLineWords = {wordCharacters}
								currentLineWidth = wordWidth
								
								-- Update potential width.
								potentialLineWidth = wordWidth
							end
						end
					else
						currentLineWidth = potentialLineWidth
						table.insert(currentLineWords, wordCharacters)
					end
				end
				
				-- Initialize the next word's with at a space's width.
				wordWidth = spaceWidth
			end
			
			-- Line break.
			if #currentLineWords > 0 and not truncated then
				-- Update text width.
				local width = currentLineWidth
				if width > textWidth then textWidth = width end
				
				-- Insert current line.
				table.insert(lines, {currentLineWords, currentLineWidth})
				-- Create new line.
				currentLineWords = {}
				currentLineWidth = 0
			end
		end
	end
	
	-- Calculate final information and render.
	local textHeight = nil
	local lineGap = 0
	local y = nil
	if yAlignment == "Top" then
		textHeight = (#lines - 1)*lineHeight + size
		y = 0
	elseif yAlignment == "Center" then
		textHeight = (#lines - 1)*lineHeight + size
		y = math.round((frameHeight - textHeight)/2)
	elseif yAlignment == "Bottom" then
		textHeight = (#lines - 1)*lineHeight + size
		y = frameHeight - textHeight
	else
		-- Justified alignment.
		y = 0
		if #lines > 1 then
			local frameHeight = frameHeight
			local linesAmount = #lines - 1
			lineGap = (frameHeight - (linesAmount*lineHeight + size))/linesAmount
			textHeight = frameHeight
		else
			textHeight = size
		end
	end
	
	if xAlignment == "Justified" then
		textWidth = frameWidth
	end
	
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
			x = 0
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
				-- Parent.
				wordContainer.Parent = lineContainer
			end
			
			-- Create characters.
			for characterIndex, character in word do
				local width = character[2]
				
				local element = createCharacter(character[1], UDim2.fromOffset(x, y), width)
				-- Numerical naming.
				if not lineSorting and not wordSorting then
					globalCharacterCount += 1
					element.Name = tostring(globalCharacterCount)
				else
					element.Name = tostring(characterIndex)
				end
				-- Parent.
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
local function handleDynamic(frame, text, customization)
	if customization.Dynamic == true then
		if frameDynamicConnections[frame] then
			-- Cache information.
			frameText[frame] = text
			frameCustomizations[frame] = customization
			-- Render.
			render(frame, text, customization, frameSizes[frame])
		else
			-- Cache information.
			frameText[frame] = text
			frameCustomizations[frame] = customization
			
			-- Setup dynamic stuff.
			local ancestorConnections = {}
			local function update()
				local size = calculateAbsoluteSize(frame)
				frameSizes[frame] = size
				render(frame, frameText[frame], frameCustomizations[frame], size)
			end
			local function fullUpdate()
				-- Calculate absolute size, and connect to size changed for ancestors.
				local instance = frame
				
				local scaleX = 1
				local scaleY = 1
				local offsetX = 0
				local offsetY = 0
				
				local rootSizeX = nil
				local rootSizeY = nil
				
				while true do
					-- Cache size values.
					local size = instance.Size
					local x = size.X
					local y = size.Y
					-- Accumulate offsets using current scale.
					offsetX = x.Offset*scaleX + offsetX
					offsetY = y.Offset*scaleY + offsetY
					-- Update scales.
					scaleX = x.Scale*scaleX
					scaleY = y.Scale*scaleY
					
					-- Traverse.
					instance = instance.Parent
					
					-- Ensure an instance.
					if not instance then break end
					
					-- Check for root gui instance, and if found, calculate root size.
					if instance:IsA("ScreenGui") then
						local camera = workspace.CurrentCamera
						if not camera then break end
						
						local viewportSize = camera.ViewportSize
						if instance.IgnoreGuiInset then
							rootSizeX = viewportSize.X
							rootSizeY = viewportSize.Y
						else
							local inset = GuiService:GetGuiInset()
							rootSizeX = viewportSize.X - inset.X
							rootSizeY = viewportSize.Y - inset.Y
						end
						
						break
					elseif instance:IsA("SurfaceGui") then
						local adornee = instance.Adornee
						if not adornee then
							adornee = instance.Parent
							if not adornee then break end
						end
						if not adornee:IsA("BasePart") then break end
						
						local face = instance.Face
						local pixelsPerStud = instance.PixelsPerStud
						local partSize = adornee.Size
						
						if face == Enum.NormalId.Front or face == Enum.NormalId.Back then
							rootSizeX = partSize.X*pixelsPerStud
							rootSizeY = partSize.Y*pixelsPerStud
						elseif face == Enum.NormalId.Left or face == Enum.NormalId.Right then
							rootSizeX = partSize.Z*pixelsPerStud
							rootSizeY = partSize.Y*pixelsPerStud
						else
							-- Top or bottom face.
							rootSizeX = partSize.X*pixelsPerStud
							rootSizeY = partSize.Z*pixelsPerStud
						end
						
						break
					else
						-- Verify instance and connect to size changed if gui.
						if instance:IsA("GuiObject") then
							table.insert(ancestorConnections, instance:GetPropertyChangedSignal("Size"):Connect(update))
						elseif not instance:IsA("Folder") then
							break
						end
					end
				end
				
				-- Final calculation and update the text.
				if rootSizeX then
					render(frame, frameText[frame], frameCustomizations[frame], Vector2.new(
						rootSizeX*scaleX + offsetX,
						rootSizeY*scaleY + offsetY
					))
				else
					render(frame, frameText[frame], frameCustomizations[frame], Vector2.zero)
				end
			end
			fullUpdate()
			local connections = nil
			connections = {
				frame:GetPropertyChangedSignal("Size"):Connect(update),
				frame.AncestryChanged:Connect(function()
					for _, connection in connections do
						connection:Disconnect()
					end
					fullUpdate()
				end),
				frame.Destroying:Connect(function()
					connections[1]:Disconnect()
					connections[2]:Disconnect()
					connections[3]:Disconnect()
					for _, connection in connections do
						connection:Disconnect()
					end
					frameDynamicConnections[frame] = nil
				end),
				ancestorConnections
			}
			frameDynamicConnections[frame] = connections
		end
	elseif customization.Dynamic == false then
		-- Disable dynamic.
		local connections = frameDynamicConnections[frame]
		if connections then
			connections[1]:Disconnect()
			connections[2]:Disconnect()
			connections[3]:Disconnect()
			for _, connection in connections[4] do
				connection:Disconnect()
			end
			frameDynamicConnections[frame] = nil
			
			frame:GetPropertyChangedSignal("Size"):Once(function()
				frameSizes[frame] = nil
			end)
		end
		
		-- Get rid of the non-true value.
		customization.Dynamic = nil
		-- Cache information.
		frameText[frame] = text
		frameCustomizations[frame] = customization
	else
		-- Get rid of the non-true value.
		customization.Dynamic = nil
		-- Cache information.
		frameText[frame] = text
		frameCustomizations[frame] = customization
	end
end
local function correctCustomization(frame, text, customization)
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
		if customization.Font == nil then
			customization.Font = defaultFont
			textBoundsParams.Font = defaultFont
		elseif typeof(customization.Font) == "Font" then
			-- Roblox font.
			textBoundsParams.Font = customization.Font
			textBoundsParams.Text = " "
			local _, result = pcall(function()
				return TextService:GetTextBoundsAsync(textBoundsParams)
			end)
			if type(result) == "string" then
				warn("Invalid font. Using default.")
				customization.Font = defaultFont
				textBoundsParams.Font = defaultFont
			end
		else
			-- Custom font.
			if not rawCustomFonts[customization.Font] then
				warn("Invalid font. Using default.")
				customization.Font = defaultFont
				textBoundsParams.Font = defaultFont
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
			if typeof(customization.StrokeColor) ~= "Color3" then
				customization.StrokeColor = defaultStrokeColor
			end
		end
		
		if typeof(customization.ShadowOffset) ~= "Vector2" then
			if typeof(customization.ShadowColor) == "Color3" then
				customization.ShadowOffset = defaultShadowOffset
			else
				customization.ShadowOffset = nil
				customization.ShadowColor = nil
			end
		elseif customization.ShadowOffset == Vector2.zero then
			customization.ShadowOffset = nil
			customization.ShadowColor = nil
		else
			if typeof(customization.ShadowColor) ~= "Color3" then
				customization.ShadowColor = defaultShadowColor
			end
		end
		
		if not truncateTypes[customization.Truncate] then
			customization.Truncate = nil
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
					customization[key] = value
				else
					warn("No customization option called '"..key.."'.")
				end
			end
			-- Correct new (merged) customization.
			correctCustomization(frame, text, customization)
		else
			customization = frameCustomizations[frame]
		end
		
		-- Size stuff and render.
		local size = frameSizes[frame]
		if not size then
			size = calculateAbsoluteSize(frame)
			frameSizes[frame] = size
			frame:GetPropertyChangedSignal("Size"):Once(function()
				frameSizes[frame] = nil
			end)
		end
		if customization.Dynamic == nil then
			-- Cache information.
			frameText[frame] = text
			frameCustomizations[frame] = customization
			-- Render.
			render(frame, text, customization, size)
		else
			handleDynamic(frame, text, customization)
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
				warn("No customization option called '"..key.."'.")
			end
		end
		-- Correct invalid customizations.
		correctCustomization(frame, text, customization)
		
		-- Connect clean-up to destroy.
		frame.Destroying:Connect(function()
			frameText[frame] = nil
			frameCustomizations[frame] = nil
			frameTextBounds[frame] = nil
			frameSizes[frame] = nil
		end)
		
		-- Size stuff and render.
		local size = calculateAbsoluteSize(frame)
		frameSizes[frame] = size
		if customization.Dynamic == nil then
			-- Cache information.
			frameText[frame] = text
			frameCustomizations[frame] = customization
			-- Render.
			render(frame, text, customization, size)
		else
			handleDynamic(frame, text, customization)
		end
	end
end

return table.freeze(module)
