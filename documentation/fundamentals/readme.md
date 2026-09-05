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
  actions:
    visible: true
---

# Introduction

You’ll be creating text using [GUI objects](https://create.roblox.com/docs/reference/engine/classes/GuiObject) as frames:

```lua
local Text = require(script.TextPlus)

local frame = script.frame

Text.Create(
	frame, -- Parent and boundary.
	"This text is awesome!" -- Text.
)
```

The text will be wrapped to fit the provided frame.

You can get the raw text content of a frame at any time like this:

```lua
Text.GetText(frame) -- Returns the text string.
```



***

{% hint style="warning" %}
**Content recognized as a part of the rendered text, including folders, will be cleared upon render.**

Adding any folders or labels might screw up the rendering process as instances are cached and re-used.
{% endhint %}
