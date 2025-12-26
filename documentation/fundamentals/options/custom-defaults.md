---
icon: gear
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

# Custom defaults

You can actually replace the default defaults with your own defaults of choice.

Simply create a new module in your game, then [tag](https://create.roblox.com/docs/studio/properties#instance-tags) it `TextDefaults`.

All you do is return a list of options whose defaults you want to modify.\
Here are the default defaults:

```lua
return {
	Font = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
	
	Size = 14,
	
	ScaleSize = nil,
	MinimumSize = nil,
	MaximumSize = nil,
	
	Color = Color3.fromRGB(0, 0, 0),
	Transparency = 0,
	
	Offset = Vector2.zero,
	Rotation = 0,
	
	StrokeSize = 5,
	StrokeColor = Color3.fromRGB(0, 0, 0),
	
	ShadowOffset = Vector2.new(0, 20),
	ShadowColor = Color3.fromRGB(50, 50, 50),
	
	LineHeight = 1,
	CharacterSpacing = 1,
	
	Truncate = false,
	
	XAlignment = "Left",
	YAlignment = "Top",
	
	WordSorting = false,
	LineSorting = false,
	
	Dynamic = false
}
```

{% hint style="success" %}
You don’t need to list all options. Those not provided will stay at the default default.
{% endhint %}

{% hint style="warning" %}
Custom defaults are not verified. Therefore, be cautious of what you set them to, as they might cause errors if set incorrectly.
{% endhint %}
