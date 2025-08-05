---
icon: gear
---

# Using the fonts

Using custom fonts is extremely simple.

Instead of providing a `Font` object, directly reference the font data, like this:

```lua
local fonts = require(path.to.Fonts)

Text.Create(
	frame,
	"Text",
	{
		Font = fonts.MyFont
	}
)
```
