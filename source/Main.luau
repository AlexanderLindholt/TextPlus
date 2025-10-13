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

v1.29.1

An efficient, robust, open-source text-rendering library for
Roblox, featuring custom fonts and advanced text control.


GitHub (repository):
https://github.com/AlexanderLindholt/TextPlus

GitBook (documentation):
https://alexxander.gitbook.io/TextPlus

DevForum (topic):
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

-- Attempt to find the plugin object.
local plugin = script:FindFirstAncestorOfClass("Plugin")

-- Signal library.
local Signal
if plugin then
	for _, instance in plugin:GetDescendants() do
		if instance:HasTag("Signal") then
			Signal = require(instance)
			if type(Signal) == "table" and Signal.new then Signal = Signal.new end
			break
		end
	end
else
	Signal = CollectionService:GetTagged("Signal")[1]
	if Signal then
		Signal = require(Signal)
		if type(Signal) == "table" and Signal.new then Signal = Signal.new end
	end
end

-- Player viewport.
local camera = workspace.CurrentCamera

-- Character for when a character is missing in a custom font.
local missingCharacter = "rbxassetid://75989824347198"

-- Options list for validation.
local optionsList = require(script.Options)
-- Option defaults.
local defaults = require(script.Defaults)
-- Options corrector.
local correctOptions = require(script.CorrectOptions)

-- Instance recycling.
local textLabelsAmount, textLabels = 0, {}
local imageLabelsAmount, imageLabels = 0, {}
local uiStrokesAmount, uiStrokes = 0, {}
local foldersAmount, folders = 0, {}
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

-- Types.
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

-- Frame data tables.
local frameText: {string} = {}
local frameOptions: {Options} = {}
local frameTextBounds: {Vector2} = {}
local frameSizeConnections: {RBXScriptSignal} = {}
local frameUpdateSignals: {Signal} = if Signal then {} else nil

-- Roblox built-in text rendering stuff.
local textBoundsParams = Instance.new("GetTextBoundsParams")
textBoundsParams.Size = 100 -- Size limit for Roblox's built-in text-rendering.

local characterWidthCache = {}

-- Custom fonts.
local userFonts = require(script.Fonts)

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
Returns the current options for a frame.
]]--
module.GetOptions = function(frame: GuiObject): Options
	-- Get, verify and return options.
	local options = frameOptions[frame]
	if not options then error("Invalid frame.", 2) end
	return frameOptions[frame]
end
--[[
Returns the last rendered text's bounds for a frame.
]]--
module.GetBounds = function(frame: GuiObject): Vector2
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
				if line:IsA("Folder") then
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
			end
		elseif lineSorting or wordSorting then -- One sorting.
			-- Global character counter.
			local index = 0
			
			-- Loop through words/lines.
			for _, folder in frame:GetChildren() do
				-- Verify instance.
				if folder:IsA("Folder") then
					-- Loop through characters.
					for _, character in folder:GetChildren() do
						-- Increment global character counter.
						index += 1
						-- Pass parameters to loop.
						coroutine.yield(index, character)
					end
				end
			end
		else -- No sorting.
			-- Identify character instance class for verification.
			local characterClass = if type(options.Font) == "table" then "TextLabel" else "ImageLabel"
			
			-- Loop through characters.
			for index, character in frame:GetChildren() do
				-- Verify instance.
				if character:IsA(characterClass) then
					-- Pass parameters to loop.
					coroutine.yield(index, character)
				end
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
			uiStrokes[uiStrokesAmount + 1] = stroke
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
				uiStrokes[uiStrokesAmount + 1] = mainStroke
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
			folders[foldersAmount + 1] = line
			
			-- Loop through words.
			for _, word in line:GetChildren() do
				-- Remove and store word folder.
				word.Parent = nil
				folders[foldersAmount + 1] = word
				
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
			folders[foldersAmount + 1] = folder
			
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
	
	-- Handle options.
	local font = options.Font
	
	local size = options.Size
	
	local color = options.Color
	local transparency = options.Transparency
	
	local offset = options.Offset; local offsetX, offsetY
	local rotation = options.Rotation
	
	local strokeSize = options.StrokeSize
	
	local shadowOffset = options.ShadowOffset; local shadowOffsetX, shadowOffsetY
	
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
			local rootSize = if root then
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
	if type(font) == "table" then
		-- Custom font.
		local image = "rbxassetid://"..tostring(font.Image)
		local scaleFactor = size/font.Size
		local characters = font.Characters
		local resampleMode = if options.Pixelated then Enum.ResamplerMode.Pixelated else Enum.ResamplerMode.Default
		
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
						math.round(x + size) + offsetX,
						math.round(y + size) + offsetY
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
						math.round(x + size) + offsetX,
						math.round(y + size) + offsetY
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
			if strokeSize < 1 then strokeSize = 1 end -- Limit again, in case it was scaled.
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
	
	-- Calculate base information.
	local textWidth = if xAlignment == "Justified" then frameWidth else 0
	
	local spaceWidth = getCharacterWidth(" ")
	
	local dotWidth = getCharacterWidth(".")
	local ellipsisWidth = dotWidth*3
	
	local lines = {}
	
	local truncated, truncate
	if truncationEnabled then
		truncate = function()
			-- Line count.
			local linesAmount = #lines
			
			-- Access last line.
			local line = lines[linesAmount]
			local lineWords = line[1]
			
			-- If the line is empty, we can simply put ellipsis here.
			if #lineWords == 0 then
				line[2] = ellipsisWidth
				
				local dot = {".", dotWidth}
				lineWords[1] = {dot, dot, dot}
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
					local charactersAmount = #wordCharacters
					wordCharacters[charactersAmount + 1] = dot
					wordCharacters[charactersAmount + 2] = dot
					wordCharacters[charactersAmount + 3] = dot
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
						local charactersAmount = #wordCharacters
						wordCharacters[charactersAmount + 1] = dot
						wordCharacters[charactersAmount + 2] = dot
						wordCharacters[charactersAmount + 3] = dot
						return
					end
				end
				
				-- Subtract remaining word width from potential, and remove word.
				potentialLineWidth -= spaceWidth + wordCharacters[1][2]
				lineWords[index] = nil
			end
			
			-- Stop or continue.
			if linesAmount == 1 then
				-- Last line, so we have no option but to put the ellipsis here.
				line[2] = ellipsisWidth
				
				local dot = {".", dotWidth}
				table.insert(lineWords, {dot, dot, dot})
			else
				-- Erase current line and repeat truncation on next line.
				lines[linesAmount] = nil
				truncate()
			end
		end
	end
	
	local lineWords = {}
	local lineWidth = -spaceWidth
	
	local lineIndex = 1
	
	for _, line in text:split("\n") do
		-- Process line.
		if line == "" then -- Means consecutive line-breaks.
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
			lineIndex += 1
			-- Reset line data.
			lineWidth = -spaceWidth
			lineWords = {}
		else
			-- Process words.
			local wordIndex = 1
			for _, word in line:split(" ") do
				if word == "" then -- Means consecutive spaces.
					lineWords[wordIndex] = false
					wordIndex += 1
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
					
					if lineWidth + wordWidth > frameWidth and wordIndex > 1 then
						-- Update text width.
						if lineWidth < frameWidth and lineWidth > textWidth then
							textWidth = lineWidth
						end
						
						-- Truncate if necessary.
						if truncationEnabled and lineIndex*lineHeight + size > frameHeight then
							-- Add word to line.
							lineWords[wordIndex] = wordCharacters
							wordIndex += 1
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
							wordIndex = 2
							lineWidth = wordWidth
						end
					else
						-- Add word to line.
						lineWords[wordIndex] = wordCharacters
						wordIndex += 1
						lineWidth += wordWidth
					end
				end
			end
			
			-- Update text width.
			if lineWidth > textWidth then
				textWidth = lineWidth
			end
			
			-- Exit if truncated.
			if truncated then break end
			
			-- Add current line.
			lines[lineIndex] = {lineWords, lineWidth}
			lineIndex += 1
			-- Reset line data.
			lineWords = {}
			lineWidth = -spaceWidth
		end
	end
	
	-- Calculate final information and render.
	local textHeight, lineGap, y
	if yAlignment == "Top" then
		textHeight = (lineIndex - 2)*lineHeight + size
		lineGap = 0
		y = 0
	elseif yAlignment == "Center" then
		textHeight = (lineIndex - 2)*lineHeight + size
		lineGap = 0
		y = math.round((frameHeight - textHeight)/2)
	elseif yAlignment == "Bottom" then
		textHeight = (lineIndex - 2)*lineHeight + size
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
			local linesAmount = lineIndex - 2
			lineGap = (frameHeight - (linesAmount*lineHeight + size))/linesAmount
			y = 0
		end
	end
	
	local globalWordCount = 0 -- In case specifically only word sorting is enabled.
	local globalCharacterCount = 0 -- In case no sorting is enabled.
	
	for lineIndex, lineData in lines do
		-- Get the current line's words.
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
			local wordsAmount = #words
			wordGap = if wordsAmount > 1 then
				(frameWidth - lineData[2])/(wordsAmount - 1)
				else
				0
			
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
		if Signal then frameUpdateSignals[frame] = Signal() end -- Create and save update signal.
		
		-- Correct options.
		if type(options) == "table" then
			for key in options do
				if not optionsList[key] then
					options[key] = nil
					warn("Invalid option '"..key.."'.")
				end
			end
		else
			options = {}
		end
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
		
		-- Handle destroying.
		frame.Destroying:Once(function()
			-- Clear frame.
			clear(frame)
			-- Destroy signals.
			if Signal then
				frameUpdateSignals[frame]:Destroy()
				frameUpdateSignals[frame] = nil
			end
			-- Remove connections.
			frameSizeConnections[frame] = nil
			-- Clear data.
			frameText[frame] = nil
			frameOptions[frame] = nil
			frameTextBounds[frame] = nil
		end)
	end
end

return table.freeze(module)
