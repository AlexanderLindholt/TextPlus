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

v1.25.0

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

-- Services.
local CollectionService = game:GetService("CollectionService")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")

-- Signal library.
local Signal = CollectionService:GetTagged("Signal")[1]
if Signal then
	Signal = require(Signal)
	if type(Signal) == "table" and Signal.new then Signal = Signal.new end
end

-- User fonts.
local fonts = CollectionService:GetTagged("Fonts")[1]
if fonts then fonts = require(fonts) end

-- Player camera.
local camera = workspace.CurrentCamera

-- Character for when a character is missing in custom fonts.
local missingCharacter = "rbxassetid://75989824347198"

-- Lists for validity checks.
local optionsList = {
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
	Justified = true
}
local yAlignments = {
	Top = true,
	Center = true,
	Bottom = true,
	Justified = true
}

-- Option defaults.
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
local userDefaults = CollectionService:GetTagged("TextDefaults")[1]
if userDefaults then
	userDefaults = require(userDefaults)
	if type(userDefaults) == "table" then
		for key in userDefaults do
			if optionsList[key] then defaults[key] = userDefaults[key] end
		end
	end
end
for key, value in defaults do
	if value == false then defaults[key] = nil end
end

-- Instance tables for recycling.
local textLabelsAmount, textLabels = 0, {}
local imageLabelsAmount, imageLabels = 0, {}
local uiStrokesAmount, uiStrokes = 0, {}
local foldersAmount, folders = 0, {}
-- Instance retrieve functions.
local function getTextLabel()
	local instance = textLabels[textLabelsAmount]
	if not instance then
		textLabelsAmount += 1
		return Instance.new("TextLabel")
	end
	textLabels[textLabelsAmount] = nil
	textLabelsAmount -= 1
	return instance
end
local function getImageLabel()
	local instance = imageLabels[imageLabelsAmount]
	if not instance then
		imageLabelsAmount += 1
		return Instance.new("ImageLabel")
	end
	imageLabels[imageLabelsAmount] = nil
	imageLabelsAmount -= 1
	return instance
end
local function getUIStroke()
	local instance = uiStrokes[uiStrokesAmount]
	if not instance then
		uiStrokesAmount += 1
		return Instance.new("UIStroke")
	end
	uiStrokes[uiStrokesAmount] = nil
	uiStrokesAmount -= 1
	return instance
end
local function getFolder()
	local instance = folders[foldersAmount]
	if not instance then
		foldersAmount += 1
		return Instance.new("Folder")
	end
	folders[foldersAmount] = nil
	foldersAmount -= 1
	return instance
end

-- Frame data tables.
local frameText = {}
local frameOptions = {}
local frameTextBounds = {}
local frameSizeConnections = {}
local frameUpdateSignals = if Signal then {} else nil

-- Roblox built-in text rendering stuff.
local textBoundsParams = Instance.new("GetTextBoundsParams")
textBoundsParams.Size = 100 -- Size limit for Roblox's built-in text-rendering.

local characterWidthCache = {}

-- Table for raw user fonts.
local rawFonts = {}

-- Verify and preload user fonts if any.
if fonts then
	if type(fonts) ~= "table" then
		warn("Font data is not a table.")
	else
		if not next(fonts) then
			warn("Font data table is empty.")
		else
			local player = Players.LocalPlayer
			local load = nil
			if player then -- If running on client.
				local screenGui = Instance.new("ScreenGui")
				screenGui.Parent = player.PlayerGui
				
				local loading = 0
				load = function(image) -- For preloading the font image assets.
					-- Increment counter for currently loading images.
					loading += 1
					
					-- Setup image label for loading the current font.
					local label = Instance.new("ImageLabel")
					label.Size = UDim2.fromOffset(1, 1) -- As small as possible.
					label.BackgroundTransparency = 1
					label.ImageTransparency = 0.999 -- Trick to make the image invisible and still have it be loaded.
					label.ResampleMode = Enum.ResamplerMode.Pixelated
					label.Image = "rbxassetid://"..tostring(image)
					label.Parent = screenGui -- It's crucial that we put it in a visible ScreenGui, otherwise it won't be loaded.
					
					-- Detect load.
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
							if not handleCharacters(value.Characters, value.Size) then -- If not valid characters then.
								warn("Invalid characters at '"..currentPath.."'.")
								table.insert(remove, key)
								continue
							end
							
							-- Insert for later freeze.
							table.insert(freeze, key)
							
							-- Insert the font into raw fonts table.
							rawFonts[value] = true
							
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
			processFonts(fonts, "Fonts")
			table.freeze(fonts)
		end
	end
end

-- Global types.
export type CustomFont = {
	Image: number,
	Size: number,
	Characters: {
		[string]: {}
	}
}
export type Options = {
	Font: Font | CustomFont?,
	
	Size: number?,
	
	ScaleSize:
		"RootX" | "RootY" | "RootXY" |
		"FrameX" | "FrameY" | "FrameXY"?,
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

-- Local types.
type Connection = {
	Connected: boolean,
	Disconnect: typeof(
		-- Erases the connection.
		function(connection: Connection) end
	)
}
type Signal<Parameters...> = {
	Connect: typeof(
		-- Connects a function.
		function(signal: Signal<Parameters...>, callback: (Parameters...) -> ()): Connection end
	),
	Once: typeof(
		-- Connects a function, then auto-disconnects after the first call.
		function(signal: Signal<Parameters...>, callback: (Parameters...) -> ()): Connection end
	),
	Wait: typeof(
		-- Yields the calling thread until the next fire.
		function(signal: Signal<Parameters...>): Parameters... end
	),
	
	Fire: typeof(
		-- Runs all connected functions, and resumes all waiting threads.
		function(signal: Signal<Parameters...>, ...: Parameters...) end
	),
	
	DisconnectAll: typeof(
		-- Erases all connections.<br>
		-- <em>Much faster than calling <code>Disconnect</code> on each.</em>
		function(signal: Signal<Parameters...>) end
	),
	Destroy: typeof(
		-- Erases all connections and methods, making the signal unusable.<br>
		-- Remove references to the signal to delete it completely.
		function(signal: Signal<Parameters...>) end
	)
}

-- Module.
local module = {}

--[[
Returns the last rendered text string for a frame.
]]--
module.GetText = function(frame: GuiObject): Options
	-- Get, verify and return text.
	local text = frameText[frame]
	if not text then error("Invalid frame.", 2) end
	return text
end
--[[
Returns the options for a frame.
]]--
module.GetOptions = function(frame: GuiObject): Options
	-- Get, verify and return options.
	local options = frameOptions[frame]
	if not options then error("Invalid frame.", 2) end
	return frameOptions[frame]
end
--[[
Returns the text bounds of a frame.
]]--
module.GetTextBounds = function(frame: GuiObject): Vector2
	-- Get, verify and return text bounds.
	local textBounds = frameTextBounds[frame]
	if not textBounds then error("Invalid frame.", 2) end
	return textBounds
end

--[[
Returns the update signal for a frame.
]]--
module.GetUpdateSignal = function(frame: GuiObject): Signal
	-- Get, verify and return signal.
	local signal = frameUpdateSignals[frame]
	if not signal then error("Invalid frame.", 2) end
	return signal
end

--[[
Returns a function for iterating through all characters in a frame.

<em>Ignores sorting folders.
Works with any sorting.</em>
]]--
module.GetCharacters = function(frame: GuiObject): {TextLabel | ImageLabel}
	-- Get and verify options.
	local options = frameOptions[frame]
	if not options then error("Invalid frame.", 2) end
	
	-- Create and return iterator.
	return coroutine.wrap(function()
		-- Identify sorting.
		local lineSorting, wordSorting = options.LineSorting, options.WordSorting
		
		if lineSorting and wordSorting then -- Full sorting.
			-- Global character counter.
			local index = 0
			
			-- Loop through lines.
			for _, line in frame:GetChildren() do
				-- Verify instance.
				if not line:IsA("Folder") then continue end
				
				-- Loop through words.
				for _, word in line:GetChildren() do
					-- Loop through characters.
					for _, character in word:GetChildren() do
						-- Increment global character counter.
						index += 1
						-- Pass parameters to loop.
						coroutine.yield(index, character)
					end
				end
			end
		elseif lineSorting or wordSorting then -- One sorting.
			-- Global character counter.
			local index = 0
			
			-- Loop through words/lines.
			for _, folder in frame:GetChildren() do
				-- Verify instance.
				if not folder:IsA("Folder") then continue end
				
				-- Loop through characters.
				for _, character in folder:GetChildren() do
					-- Increment global character counter.
					index += 1
					-- Pass parameters to loop.
					coroutine.yield(index, character)
				end
			end
		else -- No sorting.
			-- Identify character instance class for verification.
			local characterClass = if typeof(options.Font) == "Font" then "TextLabel" else "ImageLabel"
			
			-- Loop through characters.
			for index, character in frame:GetChildren() do
				-- Verify instance.
				if not character:IsA(characterClass) then continue end
				
				-- Pass parameters to loop.
				coroutine.yield(index, character)
			end
		end
	end)
end

local function clear(frame)
	-- Get options.
	local options = frameOptions[frame]
	
	-- Identify character instance class and storage table.
	local characterTable, characterClass = nil
	if type(options.Font) == "table" then
		characterTable = imageLabels
		characterClass = "ImageLabel"
	else
		characterTable = textLabels
		characterClass = "TextLabel"
	end
	
	-- Setup character stashing.
	local function stashCharacter(character)
		-- Remove and store character instance.
		character.Parent = nil
		table.insert(characterTable, character)
		
		-- Remove and store character's stroke if existent.
		local stroke = character:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Parent = nil
			table.insert(uiStrokes, stroke)
		end
		
		-- Remove and store the main character if this is a shadow.
		local main = character:FindFirstChildOfClass(characterClass)
		if main then
			-- Remove and store the main character instance.
			main.Parent = nil
			table.insert(characterTable, main)
			
			-- Remove and store the main character's stroke if existent.
			local mainStroke = main:FindFirstChildOfClass("UIStroke")
			if mainStroke then
				mainStroke.Parent = nil
				table.insert(uiStrokes, mainStroke)
			end
		end
	end
	
	-- Identify sorting.
	local lineSorting, wordSorting = options.LineSorting, options.WordSorting
	
	if lineSorting and wordSorting then -- Full sorting.
		-- Loop through lines.
		for _, line in frame:GetChildren() do
			-- Verify instance.
			if not line:IsA("Folder") then continue end
			
			-- Remove and store line folder.
			line.Parent = nil
			table.insert(folders, line)
			
			-- Loop through words.
			for _, word in line:GetChildren() do
				-- Remove and store word folder.
				word.Parent = nil
				table.insert(folders, word)
				
				-- Loop through characters.
				for _, character in word:GetChildren() do
					stashCharacter(character)
				end
			end
		end
	elseif lineSorting or wordSorting then -- One sorting.
		-- Loop through words/lines.
		for _, folder in frame:GetChildren() do
			-- Verify instance.
			if not folder:IsA("Folder") then continue end
			
			-- Remove and store word/line folder.
			folder.Parent = nil
			table.insert(folders, folder)
			
			-- Loop through characters.
			for _, character in folder:GetChildren() do
				stashCharacter(character)
			end
		end
	else -- No sorting.
		-- Loop through characters.
		for _, character in frame:GetChildren() do
			-- Verify instance.
			if not character:IsA(characterClass) then continue end
			
			stashCharacter(character)
		end
	end
end
local function render(frame, text, options)
	-- Cache frame size.
	local frameSize = frame.AbsoluteSize
	
	local frameWidth = frameSize.X
	local frameHeight = frameSize.Y
	
	-- Options values.
	local font = options.Font
	
	local size = options.Size
	
	local color = options.Color
	local transparency = options.Transparency
	
	local pixelated = options.Pixelated
	
	local offset = options.Offset local offsetX, offsetY
	local rotation = options.Rotation
	
	local strokeSize = options.StrokeSize
	
	local shadowOffset = options.ShadowOffset local shadowOffsetX, shadowOffsetY
	
	local lineHeight = options.LineHeight
	local characterSpacing = options.CharacterSpacing
	
	local truncationEnabled = options.Truncate
	
	local xAlignment = options.XAlignment
	local yAlignment = options.YAlignment
	
	local wordSorting = options.WordSorting
	local lineSorting = options.LineSorting
	
	local scaleSize = options.ScaleSize
	if scaleSize then
		-- Scale size.
		if scaleSize:sub(1, 1) == "R" then -- Relative to root.
			-- Find root size.
			local root = frame:FindFirstAncestorOfClass("GuiBase")
			local rootSize =
				if root then
					if root:IsA("ScreenGui") then
						camera.ViewportSize
					else
						root.AbsoluteSize
				else
					Vector2.zero
			
			-- Scale size.
			if scaleSize == "RootX" then
				size = size*0.01*rootSize.X
			elseif scaleSize == "RootY" then
				size = size*0.01*rootSize.Y
			else
				size = size*0.01*(rootSize.X + rootSize.Y)/2
			end
		else -- Relative to frame.
			if scaleSize == "FrameX" then
				size = size*0.01*frameWidth
			elseif scaleSize == "FrameY" then
				size = size*0.01*frameHeight
			else
				size = size*0.01*(frameWidth + frameHeight)/2
			end
		end
		
		-- Limit scaled size.
		if size < 1 then
			size = 1
		else
			-- Custom limits.
			local minimumSize = options.MinimumSize
			if minimumSize and options.Size < minimumSize then
				options.Size = minimumSize
			end
			local maximumSize = options.MaximumSize
			if maximumSize and options.Size > maximumSize then
				options.Size = maximumSize
			end
			
			-- Roblox font limit.
			if type(font) ~= "table" and size > 100 then
				size = 100
			end
		end
		
		-- Ensure integer size.
		size = math.round(size)
		
		-- Scale the related options.
		offsetX, offsetY = math.round(offset.X*0.01*size), math.round(offset.Y*0.01*size)
		if strokeSize then strokeSize = math.round(strokeSize*0.01*size) end
		if shadowOffset then shadowOffsetX, shadowOffsetY = math.round(shadowOffset.X*0.01*size), math.round(shadowOffset.Y*0.01*size) end
	else
		-- Ensure integer size.
		size = math.round(size)
		
		-- Save offsets in optimized format.
		offsetX, offsetY = offset.X, offset.Y
		if shadowOffset then shadowOffsetX, shadowOffsetY = shadowOffset.X, shadowOffset.Y end
	end
	
	lineHeight *= size
	
	-- Setup character functions.
	local getCharacterWidth, createCharacter
	do
		if type(font) == "table" then
			-- Custom font.
			local image = "rbxassetid://"..tostring(font.Image)
			local scaleFactor = size/font.Size
			local characters = font.Characters
			local resampleMode = if pixelated then Enum.ResamplerMode.Pixelated else Enum.ResamplerMode.Default
			
			--[[
			Character data (table):
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
					size*characterSpacing -- The 'missing' character is square, so height and width is the same.
			end
			if shadowOffset then
				-- Shadow.
				local shadowColor = options.ShadowColor
				local shadowTransparency = options.ShadowTransparency
				
				createCharacter = function(character, x, y)
					-- Calculate information.
					local data = characters[character]
					if data then
						-- Cache character data.
						local width = data[1]
						local height = data[2]
						local imageSize = Vector2.new(width, height)
						local imageOffset = data[3]
						
						-- Calculate position and size.
						local realX = x + data[4]*size
						local realY = y + data[5]*size
						local characterSize = UDim2.fromOffset(
							math.round(realX + width*scaleFactor) - math.round(realX),
							math.round(realY + height*scaleFactor) - math.round(realY)
						)
						
						-- Character shadow.
						local shadow = getImageLabel()
						do
							-- Stylize.
							shadow.BackgroundTransparency = 1
							shadow.Image = image
							shadow.ImageColor3 = shadowColor
							shadow.ImageTransparency = shadowTransparency
							shadow.ResampleMode = resampleMode
							-- Image cutout.
							shadow.ImageRectSize = imageSize
							shadow.ImageRectOffset = imageOffset
							-- Transformation.
							shadow.Size = characterSize
							shadow.Position = UDim2.fromOffset(
								math.round(realX) + offsetX + shadowOffsetX,
								math.round(realY) + offsetY + shadowOffsetY
							)
							shadow.Rotation = rotation
						end
						-- Main character.
						do
							-- Create and stylize.
							local main = getImageLabel()
							main.BackgroundTransparency = 1
							main.Image = image
							main.ImageColor3 = color
							main.ImageTransparency = transparency
							main.ResampleMode = resampleMode
							-- Image cutout.
							main.ImageRectSize = imageSize
							main.ImageRectOffset = imageOffset
							-- Transformation.
							main.Size = characterSize
							main.Position = UDim2.fromOffset(-shadowOffsetX, -shadowOffsetY) -- Counteract the shadow offset.
							-- Name and parent.
							main.Name = "Main"
							main.Parent = shadow
						end
						
						-- Return character instance.
						return shadow
					else -- Missing character.
						-- Create and stylize.
						local imageLabel = getImageLabel()
						imageLabel.BackgroundTransparency = 1
						imageLabel.Image = missingCharacter
						imageLabel.ImageColor3 = color
						imageLabel.ImageTransparency = transparency
						imageLabel.ResampleMode = resampleMode
						-- Transformation.
						imageLabel.Size = UDim2.fromOffset(size, size)
						imageLabel.Position = UDim2.fromOffset(
							x + offsetX,
							y + offsetY
						)
						imageLabel.Rotation = rotation
						
						-- Return character instance.
						return imageLabel
					end
				end
			else
				-- No shadow.
				createCharacter = function(character, x, y)
					local data = characters[character]
					if data then
						-- Create and stylize.
						local imageLabel = getImageLabel()
						imageLabel.BackgroundTransparency = 1
						imageLabel.Image = image
						imageLabel.ImageColor3 = color
						imageLabel.ImageTransparency = transparency
						imageLabel.ResampleMode = resampleMode
						-- Image cutout.
						local width = data[1]
						local height = data[2]
						imageLabel.ImageRectSize = Vector2.new(width, height)
						imageLabel.ImageRectOffset = data[3]
						-- Transformation.
						local realX = x + data[4]*size
						local realY = y + data[5]*size
						imageLabel.Size = UDim2.fromOffset(
							math.round(realX + width*scaleFactor) - math.round(realX),
							math.round(realY + height*scaleFactor) - math.round(realY)
						)
						imageLabel.Position = UDim2.fromOffset(
							math.round(realX) + offsetX,
							math.round(realY) + offsetY
						)
						imageLabel.Rotation = rotation
						
						-- Return character instance.
						return imageLabel
					else -- Missing character.
						-- Create and stylize.
						local imageLabel = getImageLabel()
						imageLabel.BackgroundTransparency = 1
						imageLabel.Image = missingCharacter
						imageLabel.ImageColor3 = color
						imageLabel.ImageTransparency = transparency
						-- Transformation.
						imageLabel.Size = UDim2.fromOffset(size, size)
						imageLabel.Position = UDim2.fromOffset(
							x + offsetX,
							y + offsetY
						)
						imageLabel.Rotation = rotation
						
						-- Return character instance.
						return imageLabel
					end
				end
			end
		else
			-- Roblox font.
			local strokeColor, strokeTransparency
			if strokeSize then
				if strokeSize < 1 then strokeSize = 1 end -- Limit again, in case it was scaled with size.
				strokeColor = options.StrokeColor
				strokeTransparency = options.StrokeTransparency
			end
			
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
				local shadowColor = options.ShadowColor
				local shadowTransparency = options.ShadowTransparency
				
				createCharacter = function(character, x, y, width)
					-- Calculate size.
					local characterSize = UDim2.fromOffset(math.round(width*invertedCharacterSpacing), size)
					
					-- Character shadow.
					local shadow = getTextLabel()
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
						shadow.Size = characterSize
						shadow.Rotation = rotation
						shadow.Position = UDim2.fromOffset(
							x + offsetX + shadowOffsetX,
							y + offsetY + shadowOffsetY
						)
					end
					-- Main character.
					local main = getTextLabel()
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
						main.Size = characterSize
						main.Position = UDim2.fromOffset(-shadowOffsetX, -shadowOffsetY) -- Counteract the shadow offset.
						-- Name and parent.
						main.Name = "Main"
						main.Parent = shadow
					end
					-- Apply stroke if options are given.
					if strokeSize then
						do
							local uiStroke = getUIStroke()
							uiStroke.Thickness = strokeSize
							uiStroke.Color = strokeColor
							uiStroke.Transparency = strokeTransparency
							uiStroke.Parent = main
						end
						do
							local uiStroke = getUIStroke()
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
				createCharacter = function(character, x, y, width)
					-- Create and stylize.
					local textLabel = getTextLabel()
					textLabel.BackgroundTransparency = 1
					textLabel.Text = character
					textLabel.TextSize = size
					textLabel.TextColor3 = color
					textLabel.TextTransparency = transparency
					textLabel.FontFace = font
					textLabel.TextXAlignment = Enum.TextXAlignment.Left
					textLabel.TextYAlignment = Enum.TextYAlignment.Top
					-- Transformation.
					textLabel.Size = UDim2.fromOffset(math.round(width*invertedCharacterSpacing), size)
					textLabel.Rotation = rotation
					textLabel.Position = UDim2.fromOffset(
						x + offsetX,
						y + offsetY
					)
					-- Apply stroke if options are given.
					if strokeSize then
						local uiStroke = getUIStroke()
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
	local textWidth = if xAlignment == "Justified" then frameWidth else 0
	
	local spaceWidth = getCharacterWidth(" ")
	
	local dotWidth = getCharacterWidth(".")
	local ellipsisWidth = dotWidth*3
	
	local lines = {}
	
	local lineWords = {}
	local lineWidth = 0
	
	local truncated, truncate
	if truncationEnabled then
		truncated = false
		truncate = function()
			-- Access last line.
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
				
				-- There may be empty words, caused by consecutive spaces. We skip those.
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
			
			-- Remove this line, and repeat truncation on next line.
			lines[#lines] = nil
			truncate()
		end
	end
	
	local lineIndex = 1
	for line in text:gmatch("[^\n]+") do
		-- Truncate line if necessary.
		if truncationEnabled and #lines > 0 and #lines*lineHeight + size > frameHeight then
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
				lines[lineIndex] = {lineWords, lineWidth}
				lineIndex += 1
			end
			-- Add empty line.
			lines[lineIndex] = {{}, 0}
			-- Reset line data.
			lineWidth = 0
			lineWords = {}
		else
			-- Process words.
			local wordIndex = 1
			for word in (line.." "):gmatch("([^ ]*) ") do
				if word == "" then
					lineWords[wordIndex] = false
					lineWidth += spaceWidth
				else
					local wordWidth = spaceWidth
					local wordCharacters = {}
					
					local characterIndex = 1
					for character in word:gmatch(utf8.charpattern) do
						local characterWidth = getCharacterWidth(character)
						wordWidth += characterWidth
						wordCharacters[characterIndex] = {character, characterWidth}
						characterIndex += 1
					end
					
					if lineWidth + wordWidth > frameWidth and #lineWords > 0 then
						-- Update text width.
						if lineWidth < frameWidth and lineWidth > textWidth then
							textWidth = lineWidth
						end
						
						-- Truncate if necessary.
						if truncationEnabled and (#lines + 1)*lineHeight + size > frameHeight then
							-- Add word to line.
							lineWords[wordIndex + 1] = wordCharacters
							-- Add current line.
							lines[lineIndex] = {lineWords, lineWidth}
							lineIndex += 1
							
							-- Truncate and exit.
							truncate()
							truncated = true
							break
						else
							-- Add current line.
							lines[lineIndex] = {lineWords, lineWidth}
							lineIndex += 1
							
							-- Initalize next line with the word that exceeded the boundary.
							lineWords = {wordCharacters}
							lineWidth = wordWidth
						end
					else
						-- Add word to line.
						lineWords[wordIndex] = wordCharacters
						lineWidth += wordWidth
					end
				end
				
				wordIndex += 1
			end
			
			-- Update text width.
			if lineWidth > textWidth then
				textWidth = lineWidth
			end
			
			-- Exit if truncated.
			if truncated then break end
			
			-- Add current line.
			lines[lineIndex] = {lineWords, lineWidth}
			-- Reset line data.
			lineWords = {}
			lineWidth = 0
		end
		
		-- Increment index.
		lineIndex += 1
	end
	
	if truncationEnabled then
		for _, line in lines do
			local lineWidth = line[2]
			
			if lineWidth >= frameWidth then
				-- Grab last word in the line.
				local lineWords = line[1]
				local wordCharacters = lineWords[#lineWords]
				
				-- Add ellipsis width.
				lineWidth += ellipsisWidth
				
				-- Remove characters one by one and check for space every time.
				local foundSpace = false
				for index = #wordCharacters, 2, -1 do
					lineWidth -= wordCharacters[index][2]
					wordCharacters[index] = nil
					
					if lineWidth < frameWidth then
						-- Add ellipsis and exit.
						local dot = {".", dotWidth}
						table.insert(wordCharacters, dot)
						table.insert(wordCharacters, dot)
						table.insert(wordCharacters, dot)
						
						foundSpace = true
						break
					end
				end
				
				-- Replace word with ellipsis if no space.
				if not foundSpace then
					local dot = {".", dotWidth}
					lineWords[2] = nil
					wordCharacters = lineWords[1]
					if #wordCharacters == 1 then wordCharacters[1] = nil end
					table.insert(wordCharacters, dot)
					table.insert(wordCharacters, dot)
					table.insert(wordCharacters, dot)
					lineWidth = ellipsisWidth
				end
				
				-- Update text width.
				if lineWidth > textWidth then
					textWidth = lineWidth
				end
				
				-- Update line width.
				line[2] = lineWidth
			end
		end
	end
	
	-- Calculate final information and render.
	local textHeight, lineGap, y
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
	
	local globalWordCount = 0 -- In case specifically only word sorting is enabled.
	local globalCharacterCount = 0 -- In case no sorting is enabled.
	
	for lineIndex, lineData in lines do
		-- Get and cache current line's words.
		local words = lineData[1]
		
		-- Horizontal alignment.
		local wordGap, x
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
			lineContainer = getFolder()
			lineContainer.Name = tostring(lineIndex)
			lineContainer.Parent = frame
		end
		
		-- Create words.
		for wordIndex, word in words do
			if word then -- There may be empty words, caused by consecutive spaces. These we skip.
				local wordContainer
				if wordSorting then
					wordContainer = getFolder()
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
					
					local instance = createCharacter(characterData[1], x, y, width)
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
	if Signal then frameUpdateSignals[frame]:Fire() end
end

local function correctOptions(options)
	if not scaleSizeTypes[options.ScaleSize] then
		options.ScaleSize = defaults.ScaleSize
	end
	if not scaleSizeTypes[options.ScaleSize] then
		-- Scale-size disabled.
		options.ScaleSize = nil
		options.MinimumSize = nil
		options.MaximumSize = nil
		
		if type(options.Size) ~= "number" then
			options.Size = defaults.Size
		elseif options.Size < 1 then
			options.Size = 1
		end
	else
		-- Scale-size enabled.
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
		
		-- Roblox font size limit.
		if options.Size > 100 then
			options.Size = 100
		end
	elseif typeof(font) == "Font" then -- Roblox font.
		-- Verify font.
		textBoundsParams.Font = options.Font
		textBoundsParams.Text = " "
		local _, result = pcall(TextService.GetTextBoundsAsync, TextService, textBoundsParams)
		if type(result) == "string" then
			warn("Invalid font. Fallback to default.")
			options.Font = defaults.Font
			textBoundsParams.Font = defaults.Font
		end
		
		-- Roblox font size limit.
		if options.Size > 100 then
			options.Size = 100
		end
	else
		if not rawFonts[font] then
			-- Warn about invalid font.
			warn("Invalid font. Fallback to default.")
			
			-- Apply default font.
			options.Font = defaults.Font
			textBoundsParams.Font = defaults.Font
			
			-- Roblox font size limit.
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

local function enableDynamic(frame, text)
	frameSizeConnections[frame] = frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		-- Clear current text.
		clear(frame)
		
		-- Render new text.
		local text = frameText[frame]
		if text == "" then
			frameTextBounds[frame] = Vector2.zero
			if Signal then frameUpdateSignals[frame]:Fire() end
		else
			render(frame, text, frameOptions[frame])
		end
	end)
end
local function create(frame, text, options)
	-- Cache information.
	frameText[frame] = text
	frameOptions[frame] = options
	
	-- Render new text.
	if text == "" then
		frameTextBounds[frame] = Vector2.zero
		if Signal then frameUpdateSignals[frame]:Fire() end
	else
		render(frame, text, options)
	end
end

--[[
Creates text in the specified frame.
If text is already present, it will overwrite text and merge options.

<strong>frame</strong>: The container and bounding box.
]]--
module.Create = function(frame: GuiObject, text: string, options: Options?)
	-- Find current options.
	local currentOptions = frameOptions[frame]
	
	-- Argument errors.
	if not currentOptions and (typeof(frame) ~= "Instance" or not frame:IsA("GuiObject")) then error("Invalid frame.", 2) end
	if type(text) ~= "string" then error("Invalid text.", 2) end
	
	-- Handle options.
	if currentOptions then -- Text has been created before in this frame.
		-- Clear current text.
		clear(frame)
		
		-- Handle options.
		if type(options) == "table" then
			-- Merge options.
			local newOptions = options
			options = currentOptions
			for key, value in newOptions do
				if optionsList[key] then
					if not value then
						options[key] = nil
					else
						options[key] = value
					end
				else
					warn("Invalid option '"..key.."'.")
				end
			end
			-- Correct new (merged) options.
			correctOptions(options)
		else
			options = currentOptions
		end
		
		-- Handle dynamic, calculate size, and render.
		if type(options.Dynamic) ~= "boolean" then
			options.Dynamic = defaults.Dynamic
		end
		if options.Dynamic == true then
			create(frame, text, options)
			enableDynamic(frame, text, options)
		else
			-- Dynamic disabling.
			if not options.Dynamic then
				local connection = frameSizeConnections[frame]
				if connection then connection:Disconnect() end
			end
			
			-- Get rid of the non-true value.
			options.Dynamic = nil
			
			-- Create.
			create(frame, text, options)
		end
	else -- First text creation for this frame.
		-- Create and save update signal.
		if Signal then frameUpdateSignals[frame] = Signal() end
		
		-- Ensure the options are in a table.
		if type(options) == "table" then
			-- Remove invalid options.
			for key in options do
				if not optionsList[key] then
					options[key] = nil
					warn("Invalid option '"..key.."'.")
				end
			end
			-- Correct options.
			correctOptions(options)
			
			-- Handle dynamic, calculate size, and render.
			if type(options.Dynamic) ~= "boolean" then
				options.Dynamic = defaults.Dynamic
			end
			if options.Dynamic == true then
				create(frame, text, options)
				enableDynamic(frame, text, options)
			else
				-- Dynamic disabling.
				if not options.Dynamic then
					local connection = frameSizeConnections[frame]
					if connection then connection:Disconnect() end
				end
				
				-- Get rid of the non-true value.
				options.Dynamic = nil
				
				-- Create.
				create(frame, text, options)
			end
		else
			-- Exit because we have no options to work with.
			error("Invalid options.", 2)
		end
	end
end

return table.freeze(module)
