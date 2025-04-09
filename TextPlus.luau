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

v1.9.4

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

local camera = workspace.CurrentCamera

local missingCharacter = "rbxassetid://75989824347198" -- Is used when a character is missing in a custom font.

local guiInset = GuiService:GetGuiInset()

-- Defaults.
local defaultFont = Font.new("rbxasset://fonts/families/SourceSansPro.json")

local defaultSize = 14

local defaultColor = Color3.fromRGB(0, 0, 0)
local defaultTransparency = 0

local defaultOffset = Vector2.zero
local defaultRotation = 0

local defaultStrokeSize = 1
local defaultStrokeColor = Color3.fromRGB(0, 0, 0)
local defaultStrokeTransparency = 0

local defaultShadowOffset = Vector2.new(0, 4)
local defaultShadowColor = Color3.fromRGB(50, 50, 50)
local defaultShadowTransparency = 0

local defaultLineHeight = 1
local defaultCharacterSpacing = 1

local defaultXAlignment = "Left"
local defaultYAlignment = "Top"

-- Lists for validity checks.
local customizationOptions = {
	Font = true,
	
	Size = true,
	ScaleSize = true,
	
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
	
	Dynamic = true
}

local scaleSizeTypes = {
	X = true,
	Y = true,
	XY = true
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
local frameSurfaceGuiSizes = {}

-- Roblox built-in text rendering stuff.
local textBoundsParams = Instance.new("GetTextBoundsParams")
textBoundsParams.Size = 100 -- Size limit for Roblox built-in text rendering.
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
		local remove = {} -- Because immediate removal will throw off the loop.
		local freeze = {} -- Because freezing before removal will not allow for removal.
		for key, value in parent do
			if type(value) ~= "table" then
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
	ScaleSize: "X" | "Y" | "XY",
	
	Color: Color3,
	Transparency: number,
	
	Pixelated: boolean,
	
	Offset: UDim2,
	Rotation: number,
	
	StrokeSize: number,
	StrokeColor: Color3,
	StrokeTransparency: number,
	
	ShadowOffset: number,
	ShadowColor: number,
	ShadowTransparency: number,
	
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

local function noOperation()
	
end
--[[
Returns an iterator function for looping through all characters in the specified frame.

<em>Ignores sorting folders
Works with any sorting.</em>
]]--
module.GetCharacters = function(frame: Container): {TextLabel | ImageLabel}
	-- Argument errors.
	if typeof(frame) ~= "Instance" or not (frame:IsA("Frame") or frame:IsA("ScrollingFrame") or frame:IsA("CanvasGroup")) then error("No frame received.") end
	
	-- Get and verify customization.
	local customization = frameCustomizations[frame]
	if not customization then return noOperation end
	
	-- Create and return iterator.
	return coroutine.wrap(function()
		if customization.LineSorting and customization.WordSorting then
			-- Both sortings.
			local index = 0
			for _, line in frame:GetChildren() do
				for _, word in line:GetChildren() do
					for _, character in word:GetChildren() do
						index += 1
						coroutine.yield(index, character)
					end
				end
			end
		elseif customization.LineSorting or customization.WordSorting then
			-- One sorting.
			local index = 0
			for _, folder in frame:GetChildren() do
				-- Line or word folder.
				for _, character in folder:GetChildren() do
					index += 1
					coroutine.yield(index, character)
				end
			end
		else
			-- No sorting.
			for index, character in frame:GetChildren() do
				coroutine.yield(index, character)
			end
		end
	end)
end

local function calculateAbsoluteSize(frame)
	local scaleX = 1
	local scaleY = 1
	local offsetX = 0
	local offsetY = 0
	
	local rootSizeX = nil
	local rootSizeY = nil
	
	local instance = frame
	
	while true do
		-- Cache parent.
		local parent = instance.Parent
		
		-- Ensure a parent.
		if not parent then return Vector2.zero end
		
		-- Get size.
		local grid = parent:FindFirstChildOfClass("UIGridLayout")
		local size = nil
		if grid then
			size = grid.CellSize
		else
			size = instance.Size
		end
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
		
		-- Check for root gui instance, and if found, calculate root size.
		if instance:IsA("ScreenGui") then
			-- Verify camera.
			if not camera then return Vector2.zero end
			
			-- Calculate and save viewport size.
			local viewportSize = camera.ViewportSize
			if instance.IgnoreGuiInset then
				rootSizeX = viewportSize.X
				rootSizeY = viewportSize.Y
			else
				rootSizeX = viewportSize.X - guiInset.X
				rootSizeY = viewportSize.Y - guiInset.Y
			end
			
			-- Ensure no saved surface size.
			frameSurfaceGuiSizes[frame] = nil
			
			-- Stop loop.
			break
		elseif instance:IsA("SurfaceGui") then
			-- Get and verify adornee.
			local adornee = instance.Adornee
			if not adornee then
				adornee = instance.Parent
				if not adornee then return Vector2.zero end
			end
			if not adornee:IsA("BasePart") then return Vector2.zero end
			
			-- Calculate and save surface size.
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
			frameSurfaceGuiSizes[frame] = Vector2.new(rootSizeX, rootSizeY)
			
			-- Stop loop.
			break
		else
			-- Verify instance.
			if not instance:IsA("GuiObject") and not instance:IsA("Folder") then return Vector2.zero end
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
	
	-- Customization values.
	local font = customization.Font
	
	local size = customization.Size
	local scaleSize = customization.ScaleSize
	if scaleSize then
		-- Scale size.
		local surfaceGuiSize = frameSurfaceGuiSizes[frame]
		if surfaceGuiSize then
			if scaleSize == "X" then
				size = size*0.01*surfaceGuiSize.X
			elseif scaleSize == "Y" then
				size = size*0.01*surfaceGuiSize.Y
			else
				size = size*0.01*(surfaceGuiSize.X + surfaceGuiSize.Y)/2
			end
		else
			if scaleSize == "X" then
				size = size*0.01*camera.ViewportSize.X
			elseif scaleSize == "Y" then
				size = size*0.01*camera.ViewportSize.Y
			else
				local viewportSize = camera.ViewportSize
				size = size*0.01*(viewportSize.X + viewportSize.Y)/2
			end
		end
		-- Limit scaled size.
		if size < 1 then
			size = 1
		elseif type(font) ~= "table" and size > 100 then
			size = 100
		end
	end
	
	local color = customization.Color
	local transparency = customization.Transparency
	
	local pixelated = customization.Pixelated
	
	local offset = customization.Offset
	offset = UDim2.fromOffset(offset.X*0.01*size, offset.Y*0.01*size) -- Convert Vector2 to UDim2, get the offset relative to size.
	local rotation = customization.Rotation
	
	local strokeSize = customization.StrokeSize
	
	local shadowOffset = customization.ShadowOffset
	
	local lineHeight = customization.LineHeight*size -- Get the line height relative to size.
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
			-- Custom font.
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
				local data = characters[character]
				if data then
					return data[6]*size*characterSpacing
				else
					-- Missing character.
					return size
				end
			end
			if shadowOffset then
				-- Shadow.
				shadowOffset = UDim2.fromOffset(shadowOffset.X, shadowOffset.Y) -- Convert Vector2 to UDim2.
				local shadowColor = customization.ShadowColor
				local shadowTransparency = customization.ShadowTransparency
				
				createCharacter = function(character, position)
					-- Calculate information.
					local data = characters[character]
					if data then
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
							shadow.ImageTransparency = shadowTransparency
							if pixelated then
								shadow.ResampleMode = Enum.ResamplerMode.Pixelated
							end
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
							if pixelated then
								main.ResampleMode = Enum.ResamplerMode.Pixelated
							end
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
					else -- Missing character.
						-- Create and stylize.
						local imageLabel = Instance.new("ImageLabel")
						imageLabel.BackgroundTransparency = 1
						imageLabel.Image = missingCharacter
						imageLabel.ImageColor3 = color
						imageLabel.ImageTransparency = transparency
						-- Transformation.
						imageLabel.Size = UDim2.fromOffset(size, size)
						imageLabel.Position = position + offset
						imageLabel.Rotation = rotation
						-- Return character instance.
						return imageLabel
					end
				end
			else
				-- No shadow.
				createCharacter = function(character, position)
					local data = characters[character]
					if data then
						-- Create and stylize.
						local imageLabel = Instance.new("ImageLabel")
						imageLabel.BackgroundTransparency = 1
						imageLabel.Image = image
						imageLabel.ImageColor3 = color
						imageLabel.ImageTransparency = transparency
						if pixelated then
							imageLabel.ResampleMode = Enum.ResamplerMode.Pixelated
						end
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
					else -- Missing character.
						-- Create and stylize.
						local imageLabel = Instance.new("ImageLabel")
						imageLabel.BackgroundTransparency = 1
						imageLabel.Image = missingCharacter
						imageLabel.ImageColor3 = color
						imageLabel.ImageTransparency = transparency
						-- Transformation.
						imageLabel.Size = UDim2.fromOffset(size, size)
						imageLabel.Position = position + offset
						imageLabel.Rotation = rotation
						-- Return character instance.
						return imageLabel
					end
				end
			end
		else
			-- Roblox font.
			local strokeColor = customization.StrokeColor
			local strokeTransparency = customization.StrokeTransparency
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
				-- Shadow.
				shadowOffset = UDim2.fromOffset(shadowOffset.X, shadowOffset.Y) -- Convert Vector2 to UDim2.
				local shadowColor = customization.ShadowColor
				local shadowTransparency = customization.ShadowTransparency
				
				createCharacter = function(character, position, width)
					local shadow = Instance.new("TextLabel")
					do
						-- Stylize.
						shadow.BackgroundTransparency = 1
						shadow.Text = character
						shadow.TextSize = size
						shadow.TextColor3 = shadowColor
						shadow.TextTransparency = shadowTransparency
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
							uiStroke.Transparency = strokeTransparency
							uiStroke.Parent = main
						end
						do
							local uiStroke = Instance.new("UIStroke")
							uiStroke.Thickness = strokeSize
							uiStroke.Color = strokeColor
							uiStroke.Transparency = strokeTransparency
							uiStroke.Parent = shadow
						end
					end
					-- Return character instance.
					return shadow
				end
			else
				-- No shadow.
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
						uiStroke.Transparency = strokeTransparency
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
					for startIndex, endIndex in utf8.graphemes(word) do
						local character = word:sub(startIndex, endIndex)
						local characterWidth = getCharacterWidth(character)
						table.insert(wordCharacters, {character, characterWidth})
						wordWidth += characterWidth
					end
					
					local potentialLineWidth = currentLineWidth + wordWidth
					
					if potentialLineWidth > frameWidth then
						-- Line exceeds boundary horizontally.
						if truncate and #lines*lineHeight + size > frameHeight then
							-- Truncate.
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
				
				-- Start the next word's width at a space's width.
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
					-- Cache parent.
					local parent = instance.Parent
					
					-- Ensure a parent.
					if not parent then break end
					
					-- Get size.
					local grid = parent:FindFirstChildOfClass("UIGridLayout")
					local size = nil
					if grid then
						size = grid.CellSize
						-- Connect to size changed.
						table.insert(ancestorConnections, grid:GetPropertyChangedSignal("CellSize"):Connect(update))
					else
						size = instance.Size
					end
					local x = size.X
					local y = size.Y
					-- Accumulate offsets using current scale.
					offsetX = x.Offset*scaleX + offsetX
					offsetY = y.Offset*scaleY + offsetY
					-- Update scales.
					scaleX = x.Scale*scaleX
					scaleY = y.Scale*scaleY
					
					-- Traverse.
					instance = parent
					
					-- Check for root gui instance, and if found, calculate root size.
					if instance:IsA("ScreenGui") then
						-- Verify camera.
						if not camera then break end
						
						-- Calculate and save viewport size.
						local viewportSize = camera.ViewportSize
						if instance.IgnoreGuiInset then
							rootSizeX = viewportSize.X
							rootSizeY = viewportSize.Y
						else
							rootSizeX = viewportSize.X - guiInset.X
							rootSizeY = viewportSize.Y - guiInset.Y
						end
						
						-- Ensure no saved surface size.
						frameSurfaceGuiSizes[frame] = nil
						
						-- Connect to size changed.
						table.insert(ancestorConnections, camera:GetPropertyChangedSignal("ViewportSize"):Connect(update))
						
						-- Stop loop.
						break
					elseif instance:IsA("SurfaceGui") then
						-- Get and verify adornee.
						local adornee = instance.Adornee
						if not adornee then
							adornee = instance.Parent
							if not adornee then break end
						end
						if not adornee:IsA("BasePart") then break end
						
						-- Calculate and save surface size.
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
						frameSurfaceGuiSizes[frame] = Vector2.new(rootSizeX, rootSizeY)
						
						table.insert(ancestorConnections, adornee:GetPropertyChangedSignal("Size"):Connect(update))
						
						-- Stop loop.
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
					for _, connection in ancestorConnections do
						connection:Disconnect()
					end
					render(frame, frameText[frame], frameCustomizations[frame], Vector2.zero)
				end
			end
			fullUpdate()
			local connections = nil
			connections = {
				frame:GetPropertyChangedSignal("Size"):Connect(update),
				frame.AncestryChanged:Connect(function()
					for _, connection in ancestorConnections do
						connection:Disconnect()
					end
					fullUpdate()
				end),
				frame.Destroying:Connect(function()
					connections[1]:Disconnect()
					connections[2]:Disconnect()
					connections[3]:Disconnect()
					for _, connection in ancestorConnections do
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
			for _, connection in connections[4] do -- connections[4] = ancestorConnections.
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
		
		customization.Offset = defaultOffset
		customization.Rotation = defaultRotation
		
		customization.LineHeight = defaultLineHeight
		customization.CharacterSpacing = defaultCharacterSpacing
		
		customization.XAlignment = defaultXAlignment
		customization.YAlignment = defaultYAlignment
	else
		-- Correct customizations.
		if not scaleSizeTypes[customization.ScaleSize] then
			customization.ScaleSize = nil
			
			if type(customization.Size) ~= "number" then
				customization.Size = defaultSize
			elseif customization.Size < 1 then
				customization.Size = 1
			end
		else
			if type(customization.Size) ~= "number" then
				customization.Size = defaultSize
			end
		end
		
		if customization.Font == nil then
			customization.Font = defaultFont
			textBoundsParams.Font = defaultFont
			
			-- Limit size.
			if customization.Size > 100 then
				customization.Size = 100
			end
		elseif typeof(customization.Font) == "Font" then -- Roblox font.
			-- Verify font.
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
			
			-- Limit size.
			if customization.Size > 100 then
				customization.Size = 100
			end
		else
			-- Custom font.
			if not rawCustomFonts[customization.Font] then
				warn("Invalid font. Using default.")
				customization.Font = defaultFont
				textBoundsParams.Font = defaultFont
				
				-- Limit size.
				if customization.Size > 100 then
					customization.Size = 100
				end
			end
		end
		
		if type(customization.LineHeight) ~= "number" then
			customization.LineHeight = defaultLineHeight
		elseif customization.LineHeight < 0 then
			customization.LineHeight = 0
		end
		if type(customization.CharacterSpacing) ~= "number" then
			customization.CharacterSpacing = defaultCharacterSpacing
		elseif customization.CharacterSpacing < 0 then
			customization.CharacterSpacing = 0
		end
		
		if typeof(customization.Color) ~= "Color3" then
			customization.Color = defaultColor
		end
		if type(customization.Transparency) ~= "number" then
			customization.Transparency = defaultTransparency
		end
		
		if customization.Pixelated ~= true then
			customization.Pixelated = nil
		end
		
		if typeof(customization.Offset) ~= "UDim2" then
			customization.Offset = defaultOffset
		end
		if type(customization.Rotation) ~= "number" then
			customization.Rotation = defaultRotation
		end
		
		if type(customization.StrokeSize) ~= "number" then
			if typeof(customization.StrokeColor) == "Color3" then
				customization.StrokeSize = defaultStrokeSize
				if type(customization.StrokeTransparency) ~= "number" then
					customization.StrokeTransparency = customization.Transparency
				end
			elseif type(customization.StrokeTransparency) == "number" then
				customization.StrokeSize = defaultStrokeSize
				if type(customization.StrokeColor) ~= "number" then
					customization.StrokeColor = defaultStrokeColor
				end
			else
				customization.StrokeSize = nil
				customization.StrokeColor = nil
				customization.StrokeTransparency = nil
			end
		elseif customization.StrokeSize <= 0 then
			customization.StrokeSize = nil
			customization.StrokeColor = nil
			customization.StrokeTransparency = nil
		else
			if typeof(customization.StrokeColor) ~= "Color3" then
				customization.StrokeColor = defaultStrokeColor
			end
			if type(customization.StrokeTransparency) ~= "number" then
				customization.StrokeTransparency = customization.Transparency
			end
		end
		
		if typeof(customization.ShadowOffset) ~= "Vector2" then
			if typeof(customization.ShadowColor) == "Color3" then
				customization.ShadowOffset = defaultShadowOffset
				if type(customization.ShadowTransparency) ~= "number" then
					customization.ShadowTransparency = customization.Transparency
				end
			elseif type(customization.ShadowTransparency) == "number" then
				customization.ShadowOffset = defaultShadowOffset
				if type(customization.ShadowColor) ~= "number" then
					customization.ShadowColor = defaultShadowColor
				end
			else
				customization.ShadowOffset = nil
				customization.ShadowColor = nil
				customization.ShadowTransparency = nil
			end
		elseif customization.ShadowOffset == Vector2.zero then
			customization.ShadowOffset = nil
			customization.ShadowColor = nil
			customization.ShadowTransparency = nil
		else
			if typeof(customization.ShadowColor) ~= "Color3" then
				customization.ShadowColor = defaultShadowColor
			end
			if type(customization.ShadowTransparency) ~= "number" then
				customization.ShadowTransparency = customization.Transparency
			end
		end
		
		if truncateTypes[customization.Truncate] then
			customization.Truncate = nil
		end
		
		if not xAlignments[customization.XAlignment] then
			customization.XAlignment = defaultXAlignment
		end
		if not yAlignments[customization.YAlignment] then
			customization.YAlignment = defaultYAlignment
		end
		
		if customization.WordSorting ~= true then
			customization.WordSorting = nil
		end
		if customization.LineSorting ~= true then
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
