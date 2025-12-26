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
---

# Introduction

You’ll be creating text using GUI objects as frames, like this:

```lua
local Text = require(script.TextPlus)

local frame = script.frame

Text.Create(
	frame, -- Parent and boundary.
	"This text is awesome!" -- Text.
)
```

The text will be wrapped inside of the frame.

{% hint style="success" %}
The frame can be any [GUI object](https://create.roblox.com/docs/reference/engine/classes/GuiObject).
{% endhint %}

{% hint style="warning" %}
**Content recognized as a part of the rendered text, including folders, will be cleared upon render.**

Adding any folders or labels might screw up the rendering process, since instances are cached and re-used.
{% endhint %}

\
You can get the current text of a frame at any time like this:

```lua
Text.GetText(frame)
```
