--!optimize 2

-- Services.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

-- Load and store all custom fonts.
local userFonts = {}

for _, module in CollectionService:GetTagged("Fonts") do
	if module:IsA("ModuleScript") then
		local fullModuleName = module:GetFullName()
		
		local fonts = require(module)
		
		if type(fonts) ~= "table" then
			warn("'"..fullModuleName.."' font data is not a table.")
		else
			if not next(fonts) then
				warn("'"..fullModuleName.."' font data table is empty.")
			else
				local player = Players.LocalPlayer
				local load
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
							while true do
								task.wait()
								if label.IsLoaded then
									if loading == 1 then
										screenGui:Destroy()
									else
										loading -= 1
									end
									return
								end
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
				
				local remove = {} -- Because immediate removal will throw off the loop.
				local freeze = {} -- Because freezing before removal will result in errors.
				
				local processFonts
				
				local function handleTable(key, value, currentPath)
					if value.Image or value.Size or value.Characters then
						-- Verify format.
						if type(value.Image) ~= "number" then
							warn("Missing an image ID in '"..currentPath.."'")
							table.insert(remove, key)
							return
						end
						if type(value.Size) ~= "number" then
							warn("Missing a size in '"..currentPath.."'")
							table.insert(remove, key)
							return
						end
						if type(value.Characters) ~= "table" then
							warn("Missing characters in '"..currentPath.."'")
							table.insert(remove, key)
							return
						end
						if not handleCharacters(value.Characters, value.Size) then -- If not valid characters then.
							warn("Invalid characters in '"..currentPath.."'")
							table.insert(remove, key)
							return
						end
						
						-- Insert for later freeze.
						table.insert(freeze, key)
						
						-- Insert the font into raw fonts table.
						userFonts[value] = true
						
						-- Preload images.
						if player then -- If running on client.
							load(value.Image)
						end
					else
						processFonts(value, currentPath)
						table.freeze(value)
					end
				end
				processFonts = function(parent, parentPath)
					for key, value in parent do
						if type(value) ~= "table" then
							table.insert(remove, key)
						else
							handleTable(key, value, parentPath.."."..key)
						end
					end
					
					for index, key in remove do
						parent[key] = nil
						remove[index] = nil
					end
					for index, key in freeze do
						table.freeze(parent[key])
						freeze[index] = nil
					end
				end
				
				handleTable("", fonts, fullModuleName)
				if #freeze > 0 then table.freeze(fonts) end
			end
		end
	end
end

-- Return the global user fonts table.
return userFonts