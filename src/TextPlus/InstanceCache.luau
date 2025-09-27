--!optimize 2
--!native

--[[
Manages the object pooling of GUI instances to reduce the overhead
of creating and destroying instances during text updates.
]]--

local InstanceCache = {}

local textLabelsAmount = 0
local textLabels: {TextLabel} = {}

local imageLabelsAmount = 0
local imageLabels: {ImageLabel} = {}

local uiStrokesAmount = 0
local uiStrokes: {UIStroke} = {}

local foldersAmount = 0
local folders: {Folder} = {}

local function getFromCache<T>(cache: {T}, amount: number, className: string): (T, number)
	local instance = cache[amount]
	if not instance then
		return Instance.new(className) :: T, amount
	end
	
	cache[amount] = nil
	return instance, amount - 1
end

local function stashToCache<T>(cache: {T}, amount: number, instance: T): number
	amount += 1
	cache[amount] = instance
	return amount
end

function InstanceCache.getTextLabel(): TextLabel
	local instance, newAmount = getFromCache(textLabels, textLabelsAmount, "TextLabel")
	textLabelsAmount = newAmount
	return instance
end

function InstanceCache.getImageLabel(): ImageLabel
	local instance, newAmount = getFromCache(imageLabels, imageLabelsAmount, "ImageLabel")
	imageLabelsAmount = newAmount
	return instance
end

function InstanceCache.getUIStroke(): UIStroke
	local instance, newAmount = getFromCache(uiStrokes, uiStrokesAmount, "UIStroke")
	uiStrokesAmount = newAmount
	return instance
end

function InstanceCache.getFolder(): Folder
	local instance, newAmount = getFromCache(folders, foldersAmount, "Folder")
	foldersAmount = newAmount
	return instance
end

function InstanceCache.stashCharacter(char)
	local stroke = char:FindFirstChildOfClass("UIStroke")
	
	if stroke then
		stroke.Parent = nil
		uiStrokesAmount = stashToCache(uiStrokes, uiStrokesAmount, stroke)
	end
	
	char.Parent = nil
	
	if char:IsA("ImageLabel") then
		imageLabelsAmount = stashToCache(imageLabels, imageLabelsAmount, char)
	else
		textLabelsAmount = stashToCache(textLabels, textLabelsAmount, char :: TextLabel)
	end
end

function InstanceCache.stashFolder(folder: Folder)
	folder.Parent = nil
	foldersAmount = stashToCache(folders, foldersAmount, folder)
end

return table.freeze(InstanceCache)
