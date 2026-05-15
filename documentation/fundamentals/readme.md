# Introduction

You’ll be creating text using GUI objects as frames, as such:

```lua
local Text = require(script.TextPlus)

local frame = script.frame

Text.Create(
	frame, -- Parent and boundary.
	"This text is awesome!" -- Text.
)
```

The frame acts as a container, meaning the text will be wrapped to fit the provided frame.

{% hint style="success" %}
The frame can be any [GUI object](https://create.roblox.com/docs/reference/engine/classes/GuiObject).
{% endhint %}

{% hint style="warning" %}
**Content recognized as a part of the rendered text, including folders, will be cleared upon render.**

Adding any folders or labels might screw up the rendering process as instances are cached and re-used.
{% endhint %}

***

You can get the raw text content of a frame at any time through the following function:

```lua
Text.GetText(frame)
```
