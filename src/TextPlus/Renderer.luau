--!optimize 2
--!native

--[[
Handles the core rendering logic, including layout calculation
and the creation of GUI instances.
]]--

local TextService = game:GetService("TextService")

local Renderer = {}
local characterWidthCache = {}

function Renderer.clear(frame, InstanceCache)
	local function recycle(instance)
		if instance:IsA("Folder") then
			local children = instance:GetChildren()
			
			for i = #children, 1, -1 do
				recycle(children[i])
			end
			
			InstanceCache.stashFolder(instance)
		elseif instance:IsA("GuiObject") then
			local main = instance:FindFirstChild("Main")
			
			if main then
				InstanceCache.stashCharacter(main)
			end
			
			InstanceCache.stashCharacter(instance)
		end
	end

	local children = frame:GetChildren()
	
	for i = #children, 1, -1 do
		recycle(children[i])
	end
end

function Renderer.render(frame, text, options, dependencies)
	local InstanceCache = dependencies.InstanceCache
	local FontManager = dependencies.FontManager
	local Signal = dependencies.Signal
	local camera = dependencies.camera
	local frameTextBounds = dependencies.frameTextBounds
	local frameUpdateSignals = dependencies.frameUpdateSignals
	local textBoundsParams = dependencies.textBoundsParams

	local frameSize = frame.AbsoluteSize

	local frameWidth = frameSize.X
	local frameHeight = frameSize.Y

	local font = options.Font
	local size = options.Size

	local color = options.Color
	local transparency = options.Transparency

	local pixelated = options.Pixelated

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
		if scaleSize:sub(1, 1) == "R" then
			local root = frame:FindFirstAncestorOfClass("GuiBase")
			local rootSize =
				if root then
				if root:IsA("ScreenGui") then
				camera.ViewportSize
				else
				root.AbsoluteSize
			else
				Vector2.zero

				if scaleSize == "RootX" then
					size = size * 0.01 * rootSize.X
				elseif scaleSize == "RootY" then
					size = size * 0.01 * rootSize.Y
				else
					size = size * 0.01 * (rootSize.X + rootSize.Y) / 2
				end
		else
			if scaleSize == "FrameX" then
				size = size * 0.01 * frameWidth
			elseif scaleSize == "FrameY" then
				size = size * 0.01 * frameHeight
			else
				size = size* 0.01 * (frameWidth + frameHeight) / 2
			end
		end

		if size < 1 then
			size = 1
		else
			local minimumSize = options.MinimumSize
			if minimumSize and options.Size < minimumSize then
				options.Size = minimumSize
			end
			
			local maximumSize = options.MaximumSize
			if maximumSize and options.Size > maximumSize then
				options.Size = maximumSize
			end

			if type(font) ~= "table" and size > 100 then
				size = 100
			end
		end

		size = math.round(size)
		offsetX, offsetY = math.round(offset.X * 0.01 * size), math.round(offset.Y * 0.01 * size)
		
		if strokeSize then 
			strokeSize = math.round(strokeSize * 0.01 * size) 
		end
		
		if shadowOffset then 
			shadowOffsetX, shadowOffsetY = math.round(shadowOffset.X * 0.01 * size), math.round(shadowOffset.Y * 0.01 * size) 
		end
	else
		size = math.round(size)

		offsetX, offsetY = offset.X, offset.Y
		
		if shadowOffset then 
			shadowOffsetX, shadowOffsetY = shadowOffset.X, shadowOffset.Y 
		end
	end

	lineHeight *= size

	local getCharacterWidth, createCharacter
	
	if type(font) == "table" then
		local image = "rbxassetid://"..tostring(font.Image)
		local scaleFactor = size / font.Size
		local characters = font.Characters
		local resampleMode = if pixelated then Enum.ResamplerMode.Pixelated else Enum.ResamplerMode.Default

		getCharacterWidth = function(character)
			local data = characters[character]
			return if data then data[6] * size * characterSpacing else size * characterSpacing
		end

		if shadowOffset then
			local shadowColor = options.ShadowColor
			local shadowTransparency = options.ShadowTransparency

			createCharacter = function(character, x, y)
				local data = characters[character]

				if data then
					local width = data[1]
					local height = data[2]
					local imageSize = Vector2.new(width, height)
					local imageOffset = data[3]

					local realX = x + data[4] * size
					local realY = y + data[5] * size
					local characterSize = UDim2.fromOffset(
						math.round(realX + width * scaleFactor) - math.round(realX),
						math.round(realY + height * scaleFactor) - math.round(realY)
					)

					local shadow = InstanceCache.getImageLabel()
					shadow.BackgroundTransparency = 1
					shadow.Image = image
					shadow.ImageColor3 = shadowColor
					shadow.ImageTransparency = shadowTransparency
					shadow.ResampleMode = resampleMode
					shadow.ImageRectSize = imageSize
					shadow.ImageRectOffset = imageOffset
					shadow.Size = characterSize
					shadow.Position = UDim2.fromOffset(
						math.round(realX) + offsetX + shadowOffsetX,
						math.round(realY) + offsetY + shadowOffsetY
					)
					shadow.Rotation = rotation

					local main = InstanceCache.getImageLabel()
					main.BackgroundTransparency = 1
					main.Image = image
					main.ImageColor3 = color
					main.ImageTransparency = transparency
					main.ResampleMode = resampleMode
					main.ImageRectSize = imageSize
					main.ImageRectOffset = imageOffset
					main.Size = characterSize
					main.Position = UDim2.fromOffset(-shadowOffsetX, -shadowOffsetY)
					main.Name = "Main"
					main.Parent = shadow

					return shadow
				else
					local imageLabel = InstanceCache.getImageLabel()
					imageLabel.BackgroundTransparency = 1
					imageLabel.Image = FontManager.MissingCharacter
					imageLabel.ImageColor3 = color
					imageLabel.ImageTransparency = transparency
					imageLabel.ResampleMode = resampleMode

					imageLabel.Size = UDim2.fromOffset(size, size)
					imageLabel.Position = UDim2.fromOffset(
						math.round(x + size) + offsetX,
						math.round(y + size) + offsetY
					)
					imageLabel.Rotation = rotation

					return imageLabel
				end
			end
		else
			createCharacter = function(character, x, y)
				local data = characters[character]
				if data then
					local imageLabel = InstanceCache.getImageLabel()
					imageLabel.BackgroundTransparency = 1
					imageLabel.Image = image
					imageLabel.ImageColor3 = color
					imageLabel.ImageTransparency = transparency
					imageLabel.ResampleMode = resampleMode

					local width = data[1]
					local height = data[2]
					imageLabel.ImageRectSize = Vector2.new(width, height)
					imageLabel.ImageRectOffset = data[3]

					local realX = x + data[4] * size
					local realY = y + data[5] * size
					imageLabel.Size = UDim2.fromOffset(
						math.round(realX + width * scaleFactor) - math.round(realX),
						math.round(realY + height * scaleFactor) - math.round(realY)
					)
					imageLabel.Position = UDim2.fromOffset(
						math.round(realX) + offsetX,
						math.round(realY) + offsetY
					)
					imageLabel.Rotation = rotation

					return imageLabel
				else
					local imageLabel = InstanceCache.getImageLabel()
					imageLabel.BackgroundTransparency = 1
					imageLabel.Image = FontManager.MissingCharacter
					imageLabel.ImageColor3 = color
					imageLabel.ImageTransparency = transparency
					imageLabel.Size = UDim2.fromOffset(size, size)
					imageLabel.Position = UDim2.fromOffset(
						math.round(x + size) + offsetX,
						math.round(y + size) + offsetY
					)
					imageLabel.Rotation = rotation

					return imageLabel
				end
			end
		end
	else
		local strokeColor, strokeTransparency

		if strokeSize then
			if strokeSize < 1 then 
				strokeSize = 1 
			end

			strokeColor = options.StrokeColor
			strokeTransparency = options.StrokeTransparency
		end

		local invertedCharacterSpacing = 1 / characterSpacing
		local fontKey = font.Family..tostring(font.Weight.Value)..tostring(font.Style.Value)

		getCharacterWidth = function(character)
			local characterKey = character..fontKey
			local width = characterWidthCache[characterKey]
			
			if not width then
				textBoundsParams.Text = character
				width = TextService:GetTextBoundsAsync(textBoundsParams).X * 0.01
				characterWidthCache[characterKey] = width
			end

			return width * size * characterSpacing
		end

		if shadowOffset then
			local shadowColor = options.ShadowColor
			local shadowTransparency = options.ShadowTransparency

			createCharacter = function(character, x, y, width)
				local characterSize = UDim2.fromOffset(math.round(width * invertedCharacterSpacing), size)

				local shadow = InstanceCache.getTextLabel()
				shadow.BackgroundTransparency = 1
				shadow.Text = character
				shadow.TextSize = size
				shadow.TextColor3 = shadowColor
				shadow.TextTransparency = shadowTransparency
				shadow.FontFace = font
				shadow.TextXAlignment = Enum.TextXAlignment.Left
				shadow.TextYAlignment = Enum.TextYAlignment.Top
				shadow.Size = characterSize
				shadow.Rotation = rotation
				shadow.Position = UDim2.fromOffset(
					x + offsetX + shadowOffsetX,
					y + offsetY + shadowOffsetY
				)

				local main = InstanceCache.getTextLabel()
				main.BackgroundTransparency = 1
				main.Text = character
				main.TextSize = size
				main.TextColor3 = color
				main.TextTransparency = transparency
				main.FontFace = font
				main.TextXAlignment = Enum.TextXAlignment.Left
				main.TextYAlignment = Enum.TextYAlignment.Top
				main.Size = characterSize
				main.Position = UDim2.fromOffset(-shadowOffsetX, -shadowOffsetY)
				main.Name = "Main"
				main.Parent = shadow

				if strokeSize then
					local uiStroke = InstanceCache.getUIStroke()
					uiStroke.Thickness = strokeSize
					uiStroke.Color = strokeColor
					uiStroke.Transparency = strokeTransparency
					uiStroke.Parent = main

					local uiStroke = InstanceCache.getUIStroke()
					uiStroke.Thickness = strokeSize
					uiStroke.Color = strokeColor
					uiStroke.Transparency = strokeTransparency
					uiStroke.Parent = shadow
				end

				return shadow
			end
		else
			createCharacter = function(character, x, y, width)
				local textLabel = InstanceCache.getTextLabel()
				textLabel.BackgroundTransparency = 1
				textLabel.Text = character
				textLabel.TextSize = size
				textLabel.TextColor3 = color
				textLabel.TextTransparency = transparency
				textLabel.FontFace = font
				textLabel.TextXAlignment = Enum.TextXAlignment.Left
				textLabel.TextYAlignment = Enum.TextYAlignment.Top

				textLabel.Size = UDim2.fromOffset(math.round(width * invertedCharacterSpacing), size)
				textLabel.Rotation = rotation
				textLabel.Position = UDim2.fromOffset(
					x + offsetX,
					y + offsetY
				)

				if strokeSize then
					local uiStroke = InstanceCache.getUIStroke()
					uiStroke.Thickness = strokeSize
					uiStroke.Color = strokeColor
					uiStroke.Transparency = strokeTransparency
					uiStroke.Parent = textLabel
				end

				return textLabel
			end
		end
		end

	local textWidth = if xAlignment == "Justified" then frameWidth else 0
	local spaceWidth = getCharacterWidth(" ")

	local dotWidth = getCharacterWidth(".")
	local ellipsisWidth = dotWidth * 3

	local lines = {}

	local truncated, truncate
	if truncationEnabled then
		truncate = function()
			local linesAmount = #lines

			local line = lines[linesAmount]
			local lineWords = line[1]

			if #lineWords == 0 then
				line[2] = ellipsisWidth

				local dot = {".", dotWidth}
				lineWords[1] = {dot, dot, dot}
				return
			end

			local potentialLineWidth = ellipsisWidth
			
			for _, wordCharacters in lineWords do
				if wordCharacters then
					for _, characterData in wordCharacters do
						potentialLineWidth += characterData[2]
					end
				end
				
				potentialLineWidth += spaceWidth
			end

			for index = #lineWords, 1, -1 do
				local wordCharacters = lineWords[index]

				if not wordCharacters then
					lineWords[index] = nil
					potentialLineWidth -= spaceWidth
					continue
				end

				if potentialLineWidth < frameWidth then
					line[2] = potentialLineWidth

					local dot = {".", dotWidth}
					local charactersAmount = #wordCharacters
					wordCharacters[charactersAmount + 1] = dot
					wordCharacters[charactersAmount + 2] = dot
					wordCharacters[charactersAmount + 3] = dot
					return
				end

				for index = #wordCharacters, 2, -1 do
					potentialLineWidth -= wordCharacters[index][2]
					wordCharacters[index] = nil

					if potentialLineWidth < frameWidth then
						line[2] = potentialLineWidth

						local dot = {".", dotWidth}
						local charactersAmount = #wordCharacters
						
						wordCharacters[charactersAmount + 1] = dot
						wordCharacters[charactersAmount + 2] = dot
						wordCharacters[charactersAmount + 3] = dot
						return
					end
				end

				potentialLineWidth -= spaceWidth + wordCharacters[1][2]
				lineWords[index] = nil
			end

			if linesAmount == 1 then
				line[2] = ellipsisWidth

				local dot = {".", dotWidth}
				table.insert(lineWords, {dot, dot, dot})
			else
				lines[linesAmount] = nil
				truncate()
			end
		end
	end

	local lineWords = {}
	local lineWidth = -spaceWidth

	local lineIndex = 1

	for _, line in text:split("\n") do
		if line == "" then
			if #lineWords > 0 then
				if lineWidth > textWidth then
					textWidth = lineWidth
				end

				lines[lineIndex] = {lineWords, lineWidth}
				lineIndex += 1
			end

			lines[lineIndex] = {{}, 0}
			lineIndex += 1

			lineWidth = -spaceWidth
			lineWords = {}
		else
			local wordIndex = 1
			
			for _, word in line:split(" ") do
				if word == "" then
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
						lineWidth += wordWidth
						
						if lineWidth < frameWidth and lineWidth > textWidth then
							textWidth = lineWidth
						end

						if truncationEnabled and lineIndex * lineHeight + size > frameHeight then
							lineWords[wordIndex] = wordCharacters
							wordIndex += 1

							lines[lineIndex] = {lineWords, lineWidth}
							lineIndex += 1

							truncate()
							truncated = true
							break
						else
							lines[lineIndex] = {lineWords, lineWidth}
							lineIndex += 1

							lineWords = {wordCharacters}
							wordIndex = 2
							lineWidth = wordWidth
						end
					else
						lineWords[wordIndex] = wordCharacters
						wordIndex += 1
						lineWidth += wordWidth
					end
				end
			end

			if lineWidth > textWidth then
				textWidth = lineWidth
			end

			if truncated then 
				break 
			end

			lines[lineIndex] = {lineWords, lineWidth}
			lineIndex += 1

			lineWords = {}
			lineWidth = -spaceWidth
		end
	end

	local textHeight, lineGap, y
	
	if yAlignment == "Top" then
		textHeight = (lineIndex - 2) * lineHeight + size
		lineGap = 0
		y = 0
	elseif yAlignment == "Center" then
		textHeight = (lineIndex - 2) * lineHeight + size
		lineGap = 0
		y = math.round((frameHeight - textHeight) / 2)
	elseif yAlignment == "Bottom" then
		textHeight = (lineIndex - 2) * lineHeight + size
		lineGap = 0
		y = frameHeight - textHeight
	else
		if #lines == 1 then
			textHeight = size
			lineGap = 0
			y = 0
		else
			textHeight = frameHeight
			local linesAmount = lineIndex - 2
			lineGap = (frameHeight - (linesAmount * lineHeight + size)) / linesAmount
			y = 0
		end
	end

	local globalWordCount = 0
	local globalCharacterCount = 0

	for lineIndex, lineData in lines do
		local words = lineData[1]

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
			local wordsAmount = #words
			
			wordGap = if wordsAmount > 1 then (frameWidth - lineData[2]) / (wordsAmount - 1) else 0
			x = 0
		end

		local lineContainer = frame
		if lineSorting then
			lineContainer = InstanceCache.getFolder()
			lineContainer.Name = tostring(lineIndex)
			lineContainer.Parent = frame
		end

		for wordIndex, word in words do
			if word then
				local wordContainer
				if wordSorting then
					wordContainer = InstanceCache.getFolder()
					
					if lineSorting then
						wordContainer.Name = tostring(wordIndex)
					else
						globalWordCount += 1
						wordContainer.Name = tostring(globalWordCount)
					end
					
					wordContainer.Parent = lineContainer
				else
					wordContainer = lineContainer
				end

				for characterIndex, characterData in word do
					local width = characterData[2]

					local instance = createCharacter(characterData[1], x, y, width)
					if not lineSorting and not wordSorting then
						globalCharacterCount += 1
						instance.Name = tostring(globalCharacterCount)
					else
						instance.Name = tostring(characterIndex)
					end
					instance.Parent = wordContainer
					x += width
				end
			end

			x += spaceWidth + wordGap
		end

		y += lineHeight + lineGap
	end

	frameTextBounds[frame] = Vector2.new(textWidth, textHeight)

	if Signal then 
		frameUpdateSignals[frame]:Fire() 
	end
end

return table.freeze(Renderer)