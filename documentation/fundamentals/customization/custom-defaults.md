---
icon: gear
---

# Custom defaults

You can actually replace the default defaults with your own defaults of choice.

Simply create a new module and name it whatever you want — `TextDefaults` is recommended.\
It's crucial that you give it the [tag](https://create.roblox.com/docs/studio/properties#instance-tags) `TextDefaults`, so that Text+ can identify it.

The module has to return a table, like this:

```lua
return {
	
}
```

{% hint style="success" %}
You don't need to list all customization options. Those not provided will stay at the default default.
{% endhint %}

Here's the default defaults:

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
