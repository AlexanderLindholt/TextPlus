---
layout:
  width: default
  title:
    visible: true
  description:
    visible: false
  tableOfContents:
    visible: true
  outline:
    visible: true
  pagination:
    visible: true
  metadata:
    visible: true
  tags:
    visible: true
---

# Full iteration

It’s extremely simple to iterate through the text.\
Just ensure you respect sorting.

## Simple method

It’s easy and clean to use the `GetCharacters` function, which will iterate through _all_ characters for you. The function is optimized and respects all sorting.

You can simply iterate through the characters like this:

```lua
for characterNumber, character in Text.GetCharacters(frame) do
	-- For Roblox fonts, 'character' will be a TextLabel.
	-- For custom fonts, 'character' will be an ImageLabel.
end
```

## Advanced method

Alternatively, you can manually iterate to manipulate the content.\
This is useful for deeper control and advanced effects.

Here’s an example with full sorting enabled:

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

If you have only one of the sorting types enabled, there’ll be just a single layer of folders, so you’ll have to do something like this:

```lua
for wordNumber, word in frame:GetChildren() do
	-- 'word' will be a folder.
	for characterNumber, character in word:GetChildren() do
		-- For Roblox fonts, 'character' will be a TextLabel.
		-- For custom fonts, 'character' will be an ImageLabel.
	end
end
```
