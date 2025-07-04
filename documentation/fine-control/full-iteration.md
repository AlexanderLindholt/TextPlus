# Full iteration

It's pretty simple to iterate through the text.\
Just make sure you respect sorting.

## Simple way

It's clean and easy to use the `GetCharacters` function, which will iterate through _all_ characters.\
This function is optimized and respects all sorting.

You can simply iterate through the characters like this:

```lua
for characterNumber, character in TextPlus.GetCharacters(frame) do
	-- For Roblox fonts, 'character' will be a TextLabel.
	-- For custom fonts, 'character' will be an ImageLabel.
end
```

## Advanced way

You can also manually loop through.\
This might be useful in certain cases.

Here's an example with full sorting on:

```lua
for lineNumber, line in frame:GetChildren() do
	-- 'line' will be a folder.
	for wordNumber, word in line:GetChildren() do
		-- 'word' will be a folder.
		for characterNumber, character in word:GetChildren() do
			-- For Roblox fonts, 'character' will be a TextLabel.
			-- For custom fonts, 'character' will be an ImageLabel.
		end
	end
end
```

If you have only one of the sorting types enabled, there will only be one layer of folders, and you'll have to do something like this:

```lua
for wordNumber, word in frame:GetChildren() do
	-- 'word' will be a folder.
	for characterNumber, character in word:GetChildren() do
		-- For Roblox fonts, 'character' will be a TextLabel.
		-- For custom fonts, 'character' will be an ImageLabel.
	end
end
```

