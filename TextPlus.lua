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
         TTTTTT        eeeeeeeeeeeeSeeeee       xxxxxxxxxx          tttttt       +++++++++++++++++++
         TTTTTT       eeeeeeeeeeeeeeeeeee        xxxxxxxxx          tttttt       +++++++++++++++++++
          TTTTTT       eeeee           ee       xxxxxxxxxxx         tttttt        +++   +++++       
          TTTTTT       eeeeee                   xxxxx xxxxxx       tttttt                +++++      
          TTTTTT        eeeeee    eeeeeee      xxxxx   xxxxxxx     tttttt                +++++      
          TTTTTT         eeeeeeeeeeeeeee      xxxxxx     xxxxxx    ttttttttt             +++++      
                           eeeeeeeeee        xxxxxx                 ttttttttt                       
                                                                      ttttttt                       

 - AlexanderLindholt

A lightweight, open-source text rendering module for Roblox,
featuring custom fonts and fine-control over all characters.

]]--

local TextService = game:GetService("TextService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local customFonts = require(script.CustomFonts)

local defaultSize = 14
local defaultColor = Color3.new(0, 0, 0)
local defaultTransparency = 0
local defaultFont = Font.new("rbxasset://fonts/families/SourceSansPro.json")
local defaultLineHeight = 1
local defaultCharacterSpacing = 1
local defaultXAlignment = Enum.TextXAlignment.Left
local defaultYAlignment = Enum.TextYAlignment.Top
local defaultWordSorting = false
local defaultLineSorting = false

local customizationOptions = {
	Size = true,
	Font = true,
	Color = true,
	Transparency = true,
	LineHeight = true,
	CharacterSpacing = true,
	XAlignment = true,
	YAlignment = true,
	WordSorting = true,
	LineSorting = true
}

local frameCustomizations = setmetatable({}, {__mode = "k"})

local textBoundsParams = Instance.new("GetTextBoundsParams")
textBoundsParams.Size = 100
local characterWidthCache = {}

do
	local empty = true
	for _, _ in pairs(customFonts) do
		empty = false
		break
	end
	if not empty then
		-- Verify and preload custom fonts.
		local screenGui = Instance.new("ScreenGui")
		screenGui.Parent = playerGui
		
		local loading = 0
		local function load(image)
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
		local function charactersValid(characters)
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
		for fontName, font in pairs(customFonts) do
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
					
					-- Passed all checks, so preload it for later use.
					loading += 1
					load(style.Image)
				end
			end
		end
	end
end

type Customization = {
	Size: number?,
	Font: Font?,
	Color: Color3?,
	Transparency: number?,
	LineHeight: number?,
	CharacterSpacing: number?,
	XAlignment: Enum.TextXAlignment?,
	YAlignment: Enum.TextYAlignment?,
	WordSorting: boolean?,
	LineSorting: boolean?
}
type Module = {
	Create: (frame: Frame, text: string, customization: Customization?) -> (),
	GetCharacters: (frame: Frame) -> {TextLabel | ImageLabel}
}

local module = {}

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

local function correctCustomization(customization)
	local empty = true
	for _, _ in pairs(customization) do
		empty = false
		break
	end
	if empty then
		-- Apply defaults.
		customization.Font = defaultFont
		customization.Size = defaultSize
		customization.Color = defaultColor
		customization.Transparency = defaultTransparency
		customization.LineHeight = defaultLineHeight
		customization.CharacterSpacing = defaultCharacterSpacing
		customization.XAlignment = defaultXAlignment
		customization.YAlignment = defaultYAlignment
		customization.WordSorting = defaultWordSorting
		customization.LineSorting = defaultLineSorting
	else
		-- Correct or apply defaults.
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
		if typeof(customization.XAlignment) ~= "EnumItem" or customization.XAlignment.EnumType ~= Enum.TextXAlignment then
			customization.XAlignment = defaultXAlignment
		end
		if typeof(customization.YAlignment) ~= "EnumItem" or customization.YAlignment.EnumType ~= Enum.TextYAlignment then
			customization.YAlignment = defaultYAlignment
		end
		if type(customization.WordSorting) ~= "boolean" then
			customization.WordSorting = defaultWordSorting
		end
		if type(customization.LineSorting) ~= "boolean" then
			customization.LineSorting = defaultLineSorting
		end
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
					customization[key] = value
				end
			end
			-- Correct invalid customizations.
			correctCustomization(customization)
		else
			customization = frameCustomizations[frame]
		end
	else
		-- Ensure the customization is a table.
		if type(customization) ~= "table" then
			customization = {}
		end
		-- Remove invalid customizations.
		for key, _ in pairs(customization) do
			if not customizationOptions[key] then
				customization[key] = nil
			end
		end
		-- Correct invalid customizations.
		correctCustomization(customization)
	end
	
	-- Clear any content that may interfere.
	frame:ClearAllChildren()
	
	-- Customization references.
	local font = customization.Font
	local size = customization.Size
	local color = customization.Color
	local transparency = customization.Transparency
	local lineHeight = customization.LineHeight*size
	local characterSpacing = customization.CharacterSpacing
	local xAlignment = customization.XAlignment
	local yAlignment = customization.YAlignment
	local wordSorting = customization.WordSorting
	local lineSorting = customization.LineSorting
	
	-- Save customization.
	frameCustomizations[frame] = customization
	
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
				textLabel.Position = position
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
			local fontSize = customFont.Size
			local characters = customFont.Characters
			getCharacterWidth = function(character)
				return characters[character][4]/fontSize*size
			end
			createCharacter = function(character, width, position)
				local data = characters[character]
				local imageLabel = Instance.new("ImageLabel")
				imageLabel.BackgroundTransparency = 1
				imageLabel.Image = image
				imageLabel.ImageColor3 = color
				imageLabel.ImageTransparency = transparency
				local characterSize = data[1]
				imageLabel.ImageRectSize = characterSize
				imageLabel.ImageRectOffset = data[2]
				imageLabel.Size = UDim2.fromOffset(characterSize.X/fontSize*size, characterSize.Y/fontSize*size)
				local offset = data[3]/fontSize*size
				imageLabel.Position = position + UDim2.fromOffset(offset.X, offset.Y)
				return imageLabel
			end
		end
	end
	
	-- Calculate base information.
	local frameWidth = frame.AbsoluteSize.X
	local frameHeight = frame.AbsoluteSize.Y
	local spaceWidth = getCharacterWidth(" ")*characterSpacing
	
	local linesFromText = text:split("\n")
	local lines = {}
	local currentLine = {{}, 0}
	
	for _, logicalLine in ipairs(linesFromText) do
		if logicalLine == "" then
			-- Handle empty line.
			if #currentLine[1] > 0 then
				table.insert(lines, currentLine)
				currentLine = {{}, 0}
			end
			table.insert(lines, {{}, 0})
		else
			-- Process each word in the logical line
			local wordsInLine = logicalLine:split(" ")
			for _, word in ipairs(wordsInLine) do
				-- Calculate word width.
				local wordCharacters = {}
				local wordWidth = 0
				if word == "" then -- Empty words come from consecutive spaces.
					wordWidth = spaceWidth
					wordCharacters = {{" ", spaceWidth}}
				else
					for index = 1, #word, 1 do
						local character = word:sub(index, index)
						local width = getCharacterWidth(character)*characterSpacing
						table.insert(wordCharacters, {character, width})
						wordWidth = wordWidth + width
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
						table.insert(lines, currentLine)
						currentLine = {{}, 0}
					end
					currentLine[2] = wordWidth
					table.insert(currentLine[1], {wordCharacters, wordWidth})
				else
					if #currentLine[1] > 0 then
						currentLine[2] += spaceWidth
					end
					currentLine[2] += wordWidth
					table.insert(currentLine[1], {wordCharacters, wordWidth})
				end
			end
			
			-- Force line break after logical line processing.
			if #currentLine[1] > 0 then
				table.insert(lines, currentLine)
				currentLine = {{}, 0}
			end
		end
	end
	
	-- Calculate final information and render.
	local totalTextHeight = #lines*lineHeight
	local y = 0
	if yAlignment.Name == "Center" then
		y = math.floor((frameHeight - totalTextHeight)/2)
	elseif yAlignment.Name == "Bottom" then
		y = frameHeight - totalTextHeight
	end
	
	local globalWordCount = 0 -- In case only word sorting is enabled.
	local globalCharacterCount = 0 -- In case no sorting is enabled.
	
	for lineIndex, line in ipairs(lines) do
		local lineWidth = line[2]
		local x = 0
		if xAlignment.Name == "Center" then
			x = math.round((frameWidth - lineWidth)/2)
		elseif xAlignment.Name == "Right" then
			x = frameWidth - lineWidth
		end
		
		local lineContainer = frame
		if lineSorting then -- Line sorting.
			lineContainer = Instance.new("Folder")
			lineContainer.Name = tostring(lineIndex)
			lineContainer.Parent = frame
		end
		
		for wordIndex, word in ipairs(line[1]) do
			local wordContainer = lineContainer
			if wordSorting then -- Word sorting.
				wordContainer = Instance.new("Folder")
				if lineSorting then
					wordContainer.Name = tostring(wordIndex)
				else
					globalWordCount += 1
					wordContainer.Name = tostring(globalWordCount)
				end
				wordContainer.Parent = lineContainer
			end
			
			for characterIndex, character in ipairs(word[1]) do
				local width = character[2]
				
				local element = createCharacter(character[1], width/characterSpacing, UDim2.fromOffset(x, y))
				if not lineSorting and not wordSorting then
					globalCharacterCount += 1
					element.Name = tostring(globalCharacterCount)
				else
					element.Name = tostring(characterIndex)
				end
				element.Parent = wordContainer
				
				x += width
			end
			
			x += spaceWidth
		end
		
		y += lineHeight
	end
end

return table.freeze(module) :: Module
