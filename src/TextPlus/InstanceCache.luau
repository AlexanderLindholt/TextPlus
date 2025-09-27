--!optimize 2
--!native

--[[
Manages the object pooling of GUI instances to reduce the overhead
of creating and destroying instances during text updates.
]]--

local InstanceCache = {}

local textLabelsAmount, textLabels = 0, {}
local imageLabelsAmount, imageLabels = 0, {}
local uiStrokesAmount, uiStrokes = 0, {}
local foldersAmount, folders = 0, {}

function InstanceCache.getTextLabel()
	local instance = textLabels[textLabelsAmount]
	if not instance then
		textLabelsAmount += 1
		return Instance.new("TextLabel")
	end
	
	textLabels[textLabelsAmount] = nil
	textLabelsAmount -= 1
	return instance
end

function InstanceCache.getImageLabel()
	local instance = imageLabels[imageLabelsAmount]
	if not instance then
		imageLabelsAmount += 1
		return Instance.new("ImageLabel")
	end
	
	imageLabels[imageLabelsAmount] = nil
	imageLabelsAmount -= 1
	return instance
end

function InstanceCache.getUIStroke()
	local instance = uiStrokes[uiStrokesAmount]
	if not instance then
		uiStrokesAmount += 1
		return Instance.new("UIStroke")
	end
	
	uiStrokes[uiStrokesAmount] = nil
	uiStrokesAmount -= 1
	return instance
end

function InstanceCache.getFolder()
	local instance = folders[foldersAmount]
	if not instance then
		foldersAmount += 1
		return Instance.new("Folder")
	end
	
	folders[foldersAmount] = nil
	foldersAmount -= 1
	return instance
end

function InstanceCache.stashCharacter(char)
	local stroke = char:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Parent = nil
		uiStrokesAmount += 1
		uiStrokes[uiStrokesAmount] = stroke
	end

	char.Parent = nil
	
	if char:IsA("ImageLabel") then
		imageLabelsAmount += 1
		imageLabels[imageLabelsAmount] = char
	elseif char:IsA("TextLabel") then
		textLabelsAmount += 1
		textLabels[textLabelsAmount] = char
	end
end

function InstanceCache.stashFolder(folder)
	folder.Parent = nil
	foldersAmount += 1
	folders[foldersAmount] = folder
end

return table.freeze(InstanceCache)