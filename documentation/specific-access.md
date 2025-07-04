# Specific access

You can always access the exact line, word or character you want by indexing like this:

```lua
frame["1"]
```

With some sorting enabled, you'll be able to easily access and loop through specific lines and words.



### Character (requires having no sorting)

```lua
local character = frame["1"] -- (Character-1)
-- For Roblox fonts, 'character' will be a TextLabel.
-- For custom fonts, 'character' will be an ImageLabel.
```

### Word (requires word sorting)

```lua
local word = frame["1"] -- (Word-1) — Word sorting.
local word = frame["1"]["1"] -- (Line-1 -> Word-1) — Line and word sorting.
for characterNumber, character in word:GetChildren() do
	-- For Roblox fonts, 'character' will be a TextLabel.
	-- For custom fonts, 'character' will be an ImageLabel.
end
```

### Line (requires line sorting)

```lua
local line = frame["1"] -- (Line-1)

-- Line and word sorting:
for wordNumber, word in line:GetChildren() do
	-- 'word' will be a folder.
	for characterNumber, character in word:GetChildren() do
		-- For Roblox fonts, 'character' will be a TextLabel.
		-- For custom fonts, 'character' will be an ImageLabel.
	end
end

-- Line sorting:
for characterNumber, character in line:GetChildren() do
	-- For Roblox fonts, 'character' will be a TextLabel.
	-- For custom fonts, 'character' will be an ImageLabel.
end
```
