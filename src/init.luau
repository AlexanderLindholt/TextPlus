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

Main module for Text+. This script acts as the public API,
orchestrating the various components of the library.
	
v1.27.0

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

local InstanceCache = require(script.InstanceCache)
local Options = require(script.Options)
local FontManager = require(script.FontManager)
local Renderer = require(script.Renderer)

local Signal = CollectionService:GetTagged("Signal")[1]
if Signal then
	Signal = require(Signal)
	
	if type(Signal) == "table" and Signal.new then 
		Signal = Signal.new 
	end
end

FontManager.Initialize()

local frameText = setmetatable({}, { __mode = "k" })
local frameOptions = setmetatable({}, { __mode = "k" })
local frameTextBounds = setmetatable({}, { __mode = "k" })
local frameSizeConnections = setmetatable({}, { __mode = "k" })
local frameUpdateSignals = if Signal then setmetatable({}, { __mode = "k" }) else nil

local textBoundsParams = Instance.new("GetTextBoundsParams")
textBoundsParams.Size = 100

local rendererDependencies = {
	InstanceCache = InstanceCache,
	FontManager = FontManager,
	Signal = Signal,
	frameTextBounds = frameTextBounds,
	frameUpdateSignals = frameUpdateSignals,
	textBoundsParams = textBoundsParams,
}

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
		function(connection: Connection) end
	)
}

type Signal<Parameters...> = {
	Connect: typeof(
		function(signal: Signal<Parameters...>, callback: (Parameters...) -> ()): Connection end
	),
	
	Once: typeof(
		function(signal: Signal<Parameters...>, callback: (Parameters...) -> ()): Connection end
	),
	
	Wait: typeof(
		function(signal: Signal<Parameters...>): Parameters... end
	),

	Fire: typeof(
		function(signal: Signal<Parameters...>, ...: Parameters...) end
	),

	DisconnectAll: typeof(
		function(signal: Signal<Parameters...>) end
	),
	
	Destroy: typeof(
		function(signal: Signal<Parameters...>) end
	)
}

local TextPlus = {}

TextPlus.GetText = function(frame: GuiObject): string
	local text = frameText[frame]
	if not text then error("Invalid frame.", 2) end
	return text
end

TextPlus.GetOptions = function(frame: GuiObject): Options
	local options = frameOptions[frame]
	if not options then error("Invalid frame.", 2) end
	return options
end

TextPlus.GetBounds = function(frame: GuiObject): Vector2
	local textBounds = frameTextBounds[frame]
	if not textBounds then error("Invalid frame.", 2) end
	return textBounds
end

TextPlus.GetUpdateSignal = function(frame: GuiObject): Signal
	if not Signal then
		error("Signal library not found. Ensure a Signal module is tagged with 'Signal'.", 2)
	end
	local signal = frameUpdateSignals[frame]
	if not signal then error("Invalid frame.", 2) end
	return signal
end

TextPlus.GetCharacters = function(frame: GuiObject): () -> (number, TextLabel | ImageLabel)
	local options = frameOptions[frame]
	if not options then error("Invalid frame.", 2) end

	return coroutine.wrap(function()
		local lineSorting, wordSorting = options.LineSorting, options.WordSorting

		if lineSorting and wordSorting then
			local index = 0
			
			for _, line in frame:GetChildren() do
				if line:IsA("Folder") then
					for _, word in line:GetChildren() do
						for _, character in word:GetChildren() do
							index += 1
							coroutine.yield(index, character)
						end
					end
				end
			end
		elseif lineSorting or wordSorting then
			local index = 0
			
			for _, folder in frame:GetChildren() do
				if folder:IsA("Folder") then
					for _, character in folder:GetChildren() do
						index += 1
						coroutine.yield(index, character)
					end
				end
			end
		else
			local characterClass = if type(options.Font) == "table" then "ImageLabel" else "TextLabel"
			
			for index, character in frame:GetChildren() do
				if character:IsA(characterClass) then
					coroutine.yield(index, character)
				end
			end
		end
	end)
end

local function handleTextUpdate(frame, text, options)
	frameText[frame] = text
	frameOptions[frame] = options

	if text == "" then
		frameTextBounds[frame] = Vector2.zero
		
		if Signal then
			local updateSignal = frameUpdateSignals[frame]
			
			if updateSignal then
				updateSignal:Fire()
			end
		end
	else
		Renderer.render(frame, text, options, rendererDependencies)
	end
end

local function enableDynamic(frame)
	frameSizeConnections[frame] = frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		Renderer.clear(frame, InstanceCache)
		handleTextUpdate(frame, frameText[frame], frameOptions[frame])
	end)
end

TextPlus.Create = function(frame: GuiObject, text: string, options: Options?)
	local currentOptions = frameOptions[frame]

	if not currentOptions and (typeof(frame) ~= "Instance" or not frame:IsA("GuiObject")) then
		error("Invalid frame.", 2)
	end
	
	if type(text) ~= "string" then
		error("Invalid text.", 2)
	end

	if currentOptions then
		Renderer.clear(frame, InstanceCache)

		if type(options) == "table" then
			local newOptions = options
			options = currentOptions
			
			for key, value in newOptions do
				if Options.List[key] then
					options[key] = if value then value else nil
				else
					warn("Invalid option '" .. key .. "'.")
				end
			end
			
			Options.Correct(options, FontManager.RawFonts, textBoundsParams)
		else
			options = currentOptions
		end
	else
		if Signal then
			frameUpdateSignals[frame] = Signal()
		end

		if type(options) == "table" then
			for key in options do
				if not Options.List[key] then
					options[key] = nil
					warn("Invalid option '" .. key .. "'.")
				end
			end
		else
			options = {}
		end
		
		Options.Correct(options, FontManager.RawFonts, textBoundsParams)
	end

	local wasDynamic = frameSizeConnections[frame] and frameSizeConnections[frame].Connected
	local isDynamic = options.Dynamic == true

	if not wasDynamic and isDynamic then
		enableDynamic(frame)
	elseif wasDynamic and not isDynamic then
		local connection = frameSizeConnections[frame]
		
		if connection then
			connection:Disconnect()
			frameSizeConnections[frame] = nil
		end
	end

	if options.Dynamic == false then
		options.Dynamic = nil
	end

	handleTextUpdate(frame, text, options)
end

return table.freeze(TextPlus)
