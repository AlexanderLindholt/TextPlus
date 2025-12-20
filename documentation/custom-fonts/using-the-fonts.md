# Using the fonts

Using custom fonts is extremely simple.

Instead of providing a `Font` object, just directly reference the font data table, like this:

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
