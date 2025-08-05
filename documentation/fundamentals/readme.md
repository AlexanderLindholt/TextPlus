# Introduction

You'll be creating text using gui objects as frames, like this:

```lua
local Text = require(path.to.TextPlus)

local frame = path.to.frame

Text.Create(
	frame, -- Parent and boundary.
	"This text is awesome!" -- Text.
)
```

The text will be wrapped inside of the frame.

{% hint style="success" %}
The frame can be any [gui object](https://create.roblox.com/docs/reference/engine/classes/GuiObject).
{% endhint %}



{% hint style="info" %}
Supported GUI roots are:

* ScreenGui
* SurfaceGui
{% endhint %}



{% hint style="warning" %}
Content recognized as apart of the rendered text, including folders, will be cleared upon render.\
\
No additional folders or TextLabels/ImageLabels should be created within the text frame.\
Nor should any descendants of the text's folders and labels be created.

Doing so can screw up the rendering process, as instances are cached and re-used.
{% endhint %}



You can get the current text of a frame at any time like this:

```lua
Text.GetText(frame)
```
