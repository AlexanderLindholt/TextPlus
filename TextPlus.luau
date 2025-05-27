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

v1.13.0

An efficient, robust, open-source text-rendering library for
Roblox, featuring custom fonts and advanced text control.


GitHub:
https://github.com/AlexanderLindholt/TextPlus

DevForum:
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

local CollectionService = game:GetService("CollectionService")
local TextService = game:GetService("TextService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

local SignalPlus = CollectionService:GetTagged("SignalPlus")[1]
if not SignalPlus then error("Could not find 'SignalPlus' module.") end
SignalPlus = require(SignalPlus)

local userFonts = CollectionService:GetTagged("Fonts")[1]
if not userFonts then error("Could not find 'Fonts' module.") end
userFonts = require(userFonts)

local camera = workspace.CurrentCamera

local missingCharacter = "rbxassetid://75989824347198" -- Is used when a character is missing in a custom font.

local guiInset = GuiService:GetGuiInset()

-- Customization defaults.
local defaultFont = Font.new("rbxasset://fonts/families/SourceSansPro.json")

local defaultSize = 14

local defaultColor = Color3.fromRGB(0, 0, 0)
local defaultTransparency = 0

local defaultOffset = Vector2.zero
local defaultRotation = 0

local defaultStrokeSize = 10
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
	
	Dynamic = true
}

local scaleSizeTypes = {
	X = true,
	Y = true,
	XY = true
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
local frameUpdateSignals = {}

-- Roblox built-in text rendering stuff.
local textBoundsParams = Instance.new("GetTextBoundsParams")
textBoundsParams.Size = 100 -- Size limit for Roblox built-in text rendering.
local characterWidthCache = {}

-- Create raw custom fonts table.
local rawCustomFonts = {}

-- Verify and preload custom fonts if any.
if userFonts and next(userFonts) then
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
			
			-- Precalculate normalized offset and x-advance.
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
	processFonts(userFonts, "TextPlus.CustomFonts")
	table.freeze(userFonts)
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
	Font: Font | CustomFont?,
	
	Size: number?,
	
	ScaleSize: "X" | "Y" | "XY"?,
	MinimumSize: number?,
	MaximumSize: number?,
	
	Color: Color3?,
	Transparency: number?,
	
	Pixelated: boolean?,
	
	Offset: Vector2?,
	Rotation: number?,
	
	StrokeSize: number?,
	StrokeColor: Color3?,
	StrokeTransparency: number?,
	
	ShadowOffset: Vector2?,
	ShadowColor: number?,
	ShadowTransparency: number?,
	
	LineHeight: number?,
	CharacterSpacing: number?,
	
	Truncate: boolean?,
	
	XAlignment: "Left" | "Center" | "Right" | "Justified"?,
	YAlignment: "Top" | "Center" | "Bottom" | "Justified"?,
	
	WordSorting: boolean?,
	LineSorting: boolean?,
	
	Dynamic: boolean?
}
type Container = Frame | ScrollingFrame | CanvasGroup

-- Module.
local module = {}

module.Fonts = userFonts -- Set quick access to custom fonts.

--[[
Gets the raw text string for a frame.
]]--
module.GetText = function(frame: Container): Customization
	-- Argument errors.
	if typeof(frame) ~= "Instance" or not (frame:IsA("Frame") or frame:IsA("ScrollingFrame") or frame:IsA("CanvasGroup")) then error("No frame provided.", 2) end
	
	-- Get and return text.
	return frameText[frame]
end
--[[
Gets the customization for a frame.
]]--
module.GetCustomization = function(frame: Container): Customization
	-- Argument errors.
	if typeof(frame) ~= "Instance" or not (frame:IsA("Frame") or frame:IsA("ScrollingFrame") or frame:IsA("CanvasGroup")) then error("No frame provided.", 2) end
	
	-- Get and return customization.
	return frameCustomizations[frame]
end
--[[
Gets the text bounds of a frame.
Returns <code>Vector2.zero</code> if not found.
]]--
module.GetTextBounds = function(frame: Container): Vector2
	-- Argument errors.
	if typeof(frame) ~= "Instance" or not (frame:IsA("Frame") or frame:IsA("ScrollingFrame") or frame:IsA("CanvasGroup")) then error("No frame provided.", 2) end
	
	-- Get and return text bounds.
	return frameTextBounds[frame] or Vector2.zero
end

local function noOperation()
	
end
--[[
Returns an iterator function for looping through all characters in the specified frame.

<em>Ignores sorting folders.
Works with any sorting.</em>
]]--
module.GetCharacters = function(frame: Container): {TextLabel | ImageLabel}
	-- Argument errors.
	if typeof(frame) ~= "Instance" or not (frame:IsA("Frame") or frame:IsA("ScrollingFrame") or frame:IsA("CanvasGroup")) then error("No frame provided.", 2) end
	
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

--[[
Returns the update signal for the specified frame.
]]--
module.GetUpdateSignal = function(frame: Container, signal: string)
	-- Argument errors.
	if typeof(frame) ~= "Instance" or not (frame:IsA("Frame") or frame:IsA("ScrollingFrame") or frame:IsA("CanvasGroup")) then error("No frame provided.", 2) end
	
	-- Get and return signal.
	return frameUpdateSignals[frame]
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
			if instance.SizingMode == Enum.SurfaceGuiSizingMode.PixelsPerStud then
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
			else
				local canvasSize = instance.CanvasSize
				rootSizeX = canvasSize.X
				rootSizeY = canvasSize.Y
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
		else
			-- Apply user's limits.
			local minimumSize = customization.MinimumSize
			if minimumSize and customization.Size < minimumSize then
				customization.Size = minimumSize
			end
			local maximumSize = customization.MaximumSize
			if maximumSize and customization.Size > maximumSize then
				customization.Size = maximumSize
			end
			
			-- Roblox font limit.
			if type(font) ~= "table" and size > 100 then
				size = 100
			end
		end
	end
	
	local color = customization.Color
	local transparency = customization.Transparency
	
	local pixelated = customization.Pixelated
	
	local offset = customization.Offset
	offset = UDim2.fromOffset(offset.X*0.01*size, offset.Y*0.01*size) -- Convert Vector2 to UDim2, get the offset relative to size (percentage).
	local rotation = customization.Rotation
	
	local strokeSize = customization.StrokeSize*0.01*size
	
	local shadowOffset = customization.ShadowOffset
	
	local lineHeight = customization.LineHeight*size -- Get the line height relative to size.
	local characterSpacing = customization.CharacterSpacing
	
	local truncateEnabled = customization.Truncate
	
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
				return if data then
					data[6]*size*characterSpacing
					else -- Missing character.
					size -- The 'missing' character is square, so height ('size') and width is the same.
			end
			if shadowOffset then
				-- Shadow.
				shadowOffset = UDim2.fromOffset(shadowOffset.X*0.01*size, shadowOffset.Y*0.01*size) -- Convert Vector2 to UDim2.
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
			local fontKey = font.Family..tostring(font.Weight.Value)..tostring(font.Style.Value)
			
			getCharacterWidth = function(character)
				local characterKey = character..fontKey
				local width = characterWidthCache[characterKey]
				if not width then
					textBoundsParams.Text = character
					width = TextService:GetTextBoundsAsync(textBoundsParams).X*0.01
					characterWidthCache[characterKey] = width
				end
				return width*size*characterSpacing
			end
			if shadowOffset then
				-- Shadow.
				shadowOffset = UDim2.fromOffset(shadowOffset.X*0.01*size, shadowOffset.Y*0.01*size) -- Convert Vector2 to UDim2.
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
						-- Transform.
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
	
	local dotWidth = getCharacterWidth(".")
	local ellipsisWidth = dotWidth*3
	
	local lines = {}
	
	local lineWords = {}
	local lineWidth = 0
	
	local truncated = false
	local function truncate()
		local line = lines[#lines]
		local lineWords = line[1]
		
		-- If the line is empty, we can simply put ellipsis here.
		if #lineWords == 0 then
			line[2] = ellipsisWidth
			
			local dot = {".", dotWidth}
			table.insert(lineWords, {dot, dot, dot})
			return
		end
		
		-- Calculate potential line width.
		local potentialLineWidth = ellipsisWidth
		for _, wordCharacters in lineWords do
			if wordCharacters then
				for _, characterData in wordCharacters do
					potentialLineWidth += characterData[2]
				end
			end
			potentialLineWidth += spaceWidth
		end
		
		-- Remove words one by one and check for space every time.
		for index = #lineWords, 1, -1 do
			local wordCharacters = lineWords[index]
			
			-- There may be empty words, caused by consecutive spaces. These we skip.
			if not wordCharacters then
				lineWords[index] = nil
				potentialLineWidth -= spaceWidth
				continue
			end
			
			-- Check for space at the end of the word.
			if potentialLineWidth < frameWidth then
				-- Update line width cache.
				line[2] = potentialLineWidth
				
				-- Add ellipsis and exit.
				local dot = {".", dotWidth}
				table.insert(wordCharacters, dot)
				table.insert(wordCharacters, dot)
				table.insert(wordCharacters, dot)
				return
			end
			
			-- Remove characters one by one and check for space every time.
			for index = #wordCharacters, 2, -1 do
				potentialLineWidth -= wordCharacters[index][2]
				wordCharacters[index] = nil
				
				if potentialLineWidth < frameWidth then
					-- Update line width cache.
					line[2] = potentialLineWidth
					
					-- Add ellipsis and exit.
					local dot = {".", dotWidth}
					table.insert(wordCharacters, dot)
					table.insert(wordCharacters, dot)
					table.insert(wordCharacters, dot)
					return
				end
			end
			
			-- Subtract remaining word width from potential, and remove word.
			potentialLineWidth -= spaceWidth + wordCharacters[1][2]
			lineWords[index] = nil
		end
		
		-- If last line, then we have no option but to put the ellipsis here.
		if #lines == 1 then
			line[2] = ellipsisWidth
			
			local dot = {".", dotWidth}
			table.insert(lineWords, {dot, dot, dot})
			return
		end
		
		-- Remove this line, and repeat truncation procedure on next line.
		lines[#lines] = nil
		truncate()
	end
	
	for line in text:gmatch("[^\n]+") do
		-- Truncate line if necessary.
		if truncateEnabled and #lines > 0 and #lines*lineHeight + size > frameHeight then
			truncate()
			truncated = true
			break
		end
		
		-- Process line.
		if line == "" then
			if #lineWords > 0 then
				-- Update text width.
				if lineWidth > textWidth then
					textWidth = lineWidth
				end
				-- Add current line.
				table.insert(lines, {lineWords, lineWidth})
			end
			-- Add empty line.
			table.insert(lines, {{}, 0})
			-- Reset line data.
			lineWidth = 0
			lineWords = {}
		else
			for word in (line.." "):gmatch("([^ ]*) ") do
				if word == "" then
					table.insert(lineWords, false)
					lineWidth += spaceWidth
				else
					local wordWidth = spaceWidth
					local wordCharacters = {}
					
					for character in word:gmatch(utf8.charpattern) do
						local characterWidth = getCharacterWidth(character)
						wordWidth += characterWidth
						table.insert(wordCharacters, {character, characterWidth})
					end
					
					if lineWidth + wordWidth > frameWidth then
						-- Update text width.
						if lineWidth > textWidth then
							textWidth = lineWidth
						end
						
						-- Truncate next line if necessary.
						if truncateEnabled and (#lines + 1)*lineHeight + size > frameHeight then
							-- Add word to line.
							table.insert(lineWords, wordCharacters)
							-- Add current line.
							table.insert(lines, {lineWords, lineWidth})
							
							-- Truncate.
							truncate()
							truncated = true
							break
						else
							-- Add current line.
							table.insert(lines, {lineWords, lineWidth})
							
							-- Initalize next line with the word that exceeded the boundary.
							lineWords = {wordCharacters}
							lineWidth = wordWidth
						end
					else
						-- Add word to line.
						table.insert(lineWords, wordCharacters)
						lineWidth += wordWidth
					end
				end
			end
			
			if truncated then break end
			
			-- Update text width.
			if lineWidth > textWidth then
				textWidth = lineWidth
			end
			-- Add current line.
			table.insert(lines, {lineWords, lineWidth})
			-- Reset line data.
			lineWords = {}
			lineWidth = 0
		end
	end
	
	-- Calculate final information and render.
	local textHeight = nil
	local lineGap = nil
	local y = nil
	if yAlignment == "Top" then
		textHeight = (#lines - 1)*lineHeight + size
		lineGap = 0
		y = 0
	elseif yAlignment == "Center" then
		textHeight = (#lines - 1)*lineHeight + size
		lineGap = 0
		y = math.round((frameHeight - textHeight)/2)
	elseif yAlignment == "Bottom" then
		textHeight = (#lines - 1)*lineHeight + size
		lineGap = 0
		y = frameHeight - textHeight
	else
		-- Justified alignment.
		if #lines == 1 then
			textHeight = size
			lineGap = 0
			y = 0
		else
			textHeight = frameHeight
			local linesAmount = #lines - 1
			lineGap = (frameHeight - (linesAmount*lineHeight + size))/linesAmount
			y = 0
		end
	end
	
	if xAlignment == "Justified" then
		textWidth = frameWidth
	end
	
	local globalWordCount = 0 -- In case specifically only word sorting is enabled.
	local globalCharacterCount = 0 -- In case no sorting is enabled.
	
	for lineIndex, lineData in lines do
		local words = lineData[1]
		local wordGap = nil
		local x = nil
		if xAlignment == "Left" then
			wordGap = 0
			x = 0
		elseif xAlignment == "Center" then
			wordGap = 0
			x = math.round((frameWidth - lineData[2])/2)
		elseif xAlignment == "Right" then
			wordGap = 0
			x = frameWidth - lineData[2]
		else
			-- Justified alignment.
			if #words > 1 then
				wordGap = (frameWidth - lineData[2])/(#words - 1)
			else
				wordGap = 0
			end
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
		for wordIndex, word in words do
			if word then -- There may be empty words, caused by consecutive spaces. These we skip.
				local wordContainer = nil
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
				else
					wordContainer = lineContainer
				end
				
				-- Create characters.
				for characterIndex, characterData in word do
					local width = characterData[2]
					
					local instance = createCharacter(characterData[1], UDim2.fromOffset(x, y), width)
					-- Numerical naming.
					if not lineSorting and not wordSorting then
						globalCharacterCount += 1
						instance.Name = tostring(globalCharacterCount)
					else
						instance.Name = tostring(characterIndex)
					end
					-- Parent.
					instance.Parent = wordContainer
					
					-- Add space before the next character.
					x += width
				end
			end
			
			-- Add space before the next word.
			x += spaceWidth + wordGap
		end
		
		-- Add space before the next line.
		y += lineHeight + lineGap
	end
	
	-- Save text bounds.
	frameTextBounds[frame] = Vector2.new(textWidth, textHeight)
	
	-- Fire update signal.
	frameUpdateSignals[frame]:Fire()
end
local function handleDynamic(frame, text, customization)
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
					
					-- Listen for size change.
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
					if instance.SizingMode == Enum.SurfaceGuiSizingMode.PixelsPerStud then
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
					else
						local canvasSize = instance.CanvasSize
						rootSizeX = canvasSize.X
						rootSizeY = canvasSize.Y
					end
					
					frameSurfaceGuiSizes[frame] = Vector2.new(rootSizeX, rootSizeY)
					
					-- Listen to changes.
					do
						local connection = nil
						if instance.SizingMode == Enum.SurfaceGuiSizingMode.PixelsPerStud then
							connection = instance:GetPropertyChangedSignal("PixelsPerStud"):Connect(update)
						else
							connection = instance:GetPropertyChangedSignal("CanvasSize"):Connect(update)
						end
						ancestorConnections[0] = connection
						table.insert(ancestorConnections, instance:GetPropertyChangedSignal("SizingMode"):Connect(function()
							connection:Disconnect()
							if instance.SizingMode == Enum.SurfaceGuiSizingMode.PixelsPerStud then
								connection = instance:GetPropertyChangedSignal("PixelsPerStud"):Connect(update)
							else
								connection = instance:GetPropertyChangedSignal("CanvasSize"):Connect(update)
							end
							ancestorConnections[0] = connection
							update()
						end))
					end
					do
						local connection = adornee:GetPropertyChangedSignal("Size"):Connect(update)
						table.insert(ancestorConnections, instance:GetPropertyChangedSignal("Adornee"):Connect(function()
							connection:Disconnect()
							adornee = instance.Adornee
							if adornee then
								connection = instance.Adornee:GetPropertyChangedSignal("Size"):Connect(update) then
							else
								connection = nil
							end
							ancestorConnections[-1] = connection
							update()
						end))
					end
					table.insert(ancestorConnections, instance:GetPropertyChangedSignal("Face"):Connect(update))
					
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
			
			if rootSizeX then
				-- Final calculation.
				local size = Vector2.new(
					rootSizeX*scaleX + offsetX,
					rootSizeY*scaleY + offsetY
				)
				-- Cache size.
				frameSizes[frame] = size
				-- Render.
				render(frame, frameText[frame], frameCustomizations[frame], size)
			else
				-- Remove all connections from invalid ancestor.
				for index, connection in ancestorConnections do
					connection:Disconnect()
					ancestorConnections[index] = nil
				end
				-- Cache size.
				frameSizes[frame] = Vector2.zero
				-- Render.
				render(frame, frameText[frame], frameCustomizations[frame], Vector2.zero)
			end
		end
		fullUpdate()
		local connections = nil
		connections = {
			frame:GetPropertyChangedSignal("Size"):Connect(update),
			frame.AncestryChanged:Connect(function()
				for index, connection in ancestorConnections do
					connection:Disconnect()
					ancestorConnections[index] = nil
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
end
local function disableDynamic(frame, customization)
	-- Remove connections.
	local connections = frameDynamicConnections[frame]
	if connections then
		connections[1]:Disconnect()
		connections[2]:Disconnect()
		connections[3]:Disconnect()
		for _, connection in connections[4] do -- connections[4] = ancestorConnections.
			connection:Disconnect()
		end
		frameDynamicConnections[frame] = nil
	end
	
	-- Get rid of the non-true value.
	customization.Dynamic = nil
end
local function correctCustomization(customization)
	if not scaleSizeTypes[customization.ScaleSize] then
		-- Scale-size disabled.
		customization.ScaleSize = nil
		customization.MinimumSize = nil
		customization.MaximumSize = nil
		
		if type(customization.Size) ~= "number" then
			customization.Size = defaultSize
		elseif customization.Size < 1 then
			customization.Size = 1
		end
	else
		-- Scale-size enabled.
		local minimumSize = customization.MinimumSize
		if type(minimumSize) ~= "number" then
			customization.MinimumSize = nil
		elseif minimumSize < 1 then
			customization.MinimumSize = 1
		end
		local maximumSize = customization.MaximumSize
		if type(maximumSize) ~= "number" then
			customization.MaximumSize = nil
		elseif maximumSize < 1 then
			customization.MaximumSize = 1
		end
		
		if type(customization.Size) ~= "number" then
			customization.Size = defaultSize
		end
	end
	
	local font = customization.Font
	if font == nil then
		customization.Font = defaultFont
		textBoundsParams.Font = defaultFont
		
		-- Limit size.
		if customization.Size > 100 then
			customization.Size = 100
		end
	elseif typeof(font) == "Font" then -- Roblox font.
		-- Verify font.
		textBoundsParams.Font = customization.Font
		textBoundsParams.Text = " "
		local _, result = pcall(TextService.GetTextBoundsAsync, TextService, textBoundsParams)
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
		if not rawCustomFonts[font] then
			warn("Invalid font. Using default.")
			customization.Font = defaultFont
			textBoundsParams.Font = defaultFont
			
			-- Limit size.
			if customization.Size > 100 then
				customization.Size = 100
			end
		end
	end
	
	local lineHeight = customization.LineHeight
	if type(lineHeight) ~= "number" then
		customization.LineHeight = defaultLineHeight
	elseif lineHeight < 0 then
		customization.LineHeight = 0
	end
	local characterSpacing = customization.CharacterSpacing
	if type(characterSpacing) ~= "number" then
		customization.CharacterSpacing = defaultCharacterSpacing
	elseif characterSpacing < 0 then
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
	
	local offset = customization.Offset
	if typeof(offset) ~= "Vector2" then
		customization.Offset = defaultOffset
	else
		if offset.X < 1 then
			customization.ShadowOffset = 1
		end
		if offset.Y < 1 then
			customization.ShadowOffset = 1
		end
	end
	if type(customization.Rotation) ~= "number" then
		customization.Rotation = defaultRotation
	end
	
	local strokeSize = customization.StrokeSize
	local strokeColor = customization.StrokeColor
	local strokeTransparency = customization.StrokeTransparency
	if type(strokeSize) ~= "number" then
		if typeof(strokeColor) == "Color3" then
			customization.StrokeSize = defaultStrokeSize
			if type(strokeTransparency) ~= "number" then
				customization.StrokeTransparency = customization.Transparency
			end
		elseif type(strokeTransparency) == "number" then
			customization.StrokeSize = defaultStrokeSize
			if type(strokeColor) ~= "number" then
				customization.StrokeColor = defaultStrokeColor
			end
		else
			customization.StrokeSize = nil
			customization.StrokeColor = nil
			customization.StrokeTransparency = nil
		end
	else
		if strokeSize < 1 then
			customization.StrokeSize = 1
		end
		if typeof(strokeColor) ~= "Color3" then
			customization.StrokeColor = defaultStrokeColor
		end
		if type(strokeTransparency) ~= "number" then
			customization.StrokeTransparency = customization.Transparency
		end
	end
	
	local shadowOffset = customization.ShadowOffset
	local shadowColor = customization.ShadowColor
	local shadowTransparency = customization.ShadowTransparency
	if typeof(shadowOffset) ~= "Vector2" then
		if typeof(shadowColor) == "Color3" then
			shadowOffset = defaultShadowOffset
			if type(shadowTransparency) ~= "number" then
				customization.ShadowTransparency = customization.Transparency
			end
		elseif type(shadowTransparency) == "number" then
			customization.ShadowOffset = defaultShadowOffset
			if type(shadowColor) ~= "number" then
				customization.ShadowColor = defaultShadowColor
			end
		else
			customization.ShadowOffset = nil
			customization.ShadowColor = nil
			customization.ShadowTransparency = nil
		end
	else
		if shadowOffset.X < 1 then
			customization.ShadowOffset = 1
		end
		if shadowOffset.Y < 1 then
			customization.ShadowOffset = 1
		end
		if typeof(shadowColor) ~= "Color3" then
			customization.ShadowColor = defaultShadowColor
		end
		if type(shadowTransparency) ~= "number" then
			customization.ShadowTransparency = customization.Transparency
		end
	end
	
	if customization.Truncate ~= true then
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
local function create(frame, text, customization)
	-- Cache information.
	frameText[frame] = text
	frameCustomizations[frame] = customization
	-- Calculate size.
	local size = frameSizes[frame]
	if not size then
		size = calculateAbsoluteSize(frame)
		-- Temporarily cache size.
		frameSizes[frame] = size
		frame:GetPropertyChangedSignal("Size"):Once(function()
			frameSizes[frame] = nil
		end)
	end
	-- Render.
	render(frame, text, customization, size)
end
--[[
Creates text inside of a specified frame.
If text is already present, it will overwrite text and merge customizations.

<strong>frame</strong>: The container and bounding box.
]]--
module.Create = function(frame: Container, text: string, customization: Customization?)
	-- Argument errors.
	if not text then error("No text provided.", 2) end
	if text == "" then error("If you want to clear the text, use 'frame:ClearAllChildren()' instead.", 2) end
	if typeof(frame) ~= "Instance" or not (frame:IsA("Frame") or frame:IsA("ScrollingFrame") or frame:IsA("CanvasGroup")) then error("No frame provided.", 2) end
	
	-- Handle customization.
	if frameCustomizations[frame] then
		if type(customization) == "table" then
			-- Merge customizations.
			local newCustomization = customization
			customization = frameCustomizations[frame]
			for key, value in newCustomization do
				if customizationOptions[key] then
					if not value then
						customization[key] = nil
					else
						customization[key] = value
					end
				else
					warn("No customization option called '"..key.."'.")
				end
			end
			-- Correct new (merged) customization.
			correctCustomization(customization)
		else
			customization = frameCustomizations[frame]
		end
		
		-- Handle dynamic, calculate size, and render.
		if customization.Dynamic == true then
			handleDynamic(frame, text, customization)
		else
			-- Dynamic disabling.
			if customization.Dynamic == false then
				disableDynamic(frame, customization)
			end
			
			-- Create.
			create(frame, text, customization)
		end
	else
		-- Create and save update signal.
		frameUpdateSignals[frame] = SignalPlus()
		
		-- Ensure the customization is a table.
		if type(customization) == "table" then
			-- Remove invalid customization options.
			for key in customization do
				if not customizationOptions[key] then
					customization[key] = nil
					warn("No customization option called '"..key.."'.")
				end
			end
			-- Correct customization.
			correctCustomization(customization)
			
			-- Handle dynamic, calculate size, and render.
			if customization.Dynamic == true then
				handleDynamic(frame, text, customization)
			else
				-- Dynamic disabling.
				if customization.Dynamic == false then
					disableDynamic(frame, text, customization)
				end
				
				-- Create.
				create(frame, text, customization)
			end
		else
			-- Create with default customization.
			create(frame, text, {
				Font = defaultFont,
				
				Size = defaultSize,
				
				Color = defaultColor,
				Transparency = defaultTransparency,
				
				Offset = defaultOffset,
				Rotation = defaultRotation,
				
				LineHeight = defaultLineHeight,
				CharacterSpacing = defaultCharacterSpacing,
				
				XAlignment = defaultXAlignment,
				YAlignment = defaultYAlignment
				
				-- We simply don't include optional customizations.
			})
		end
	end
end

return table.freeze(module)
