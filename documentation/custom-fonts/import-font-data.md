# Import font data

Open the fonts data module.

Add your font like this:

```lua
return {
	MyFont = -- Paste converted XML here.
}
```

Add your image id for the font in the same table as the `Size` and `Characters`, like this:

```lua
MyFont = {
	Image = 0, -- Image id.
	-- Converted XML:
	Size = 32,
	Characters = {
		
	}
}
```

For fonts that have multiple weights and/or styles, it's recommended to use the following format:

```lua
return {
	-- Fonts.
	MyFont = {
		-- Weights.
		Bold = {
			-- Styles.
			Italic = {
				Image = 0, -- Image id.
				-- Converted XML:
				Size = 32,
				Characters = {
					
				}
			}
		}
	}
}
```

{% hint style="success" %}
You will automatically be warned, in the output, about any mistakes you make in the font data module.
{% endhint %}

