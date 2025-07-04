# Fonts

`Font` is one of the many customization options.

It accepts two types of data:

* [A `Font` object](#user-content-fn-1)[^1].
* A custom font data table.

You can use it like this:

```lua
TextPlus.Create(
	frame,
	"This text is awesome!",
	{
		Font = Font.new(
			"rbxasset://fonts/families/Arial.json", -- Family.
			Enum.FontWeight.Regular, -- Weight.
			Enum.FontStyle.Normal -- Style.
		)
	}
)
```

### Built-in fonts

You can find a lot of fonts on [the documentation page](https://create.roblox.com/docs/reference/engine/datatypes/Font).

Simply copy the asset id from the font list and paste it into the `Font` object's `Family`.

### Creator store fonts

Alternatively, browse many more fonts at [the creator store](https://create.roblox.com/store/fonts).

Click `Get Font`.\
Create a `TextLabel` in Roblox Studio and apply the font to it.\
Make sure you have the `TextLabel` selected, then run this in the command bar:

```lua
print(game.Selection:Get()[1].FontFace.Family)
```

It will output the asset id you need.\
Simply copy-and-paste it into the `Font` object's `Family`.

### Custom fonts

If it's still not enough, custom fonts offer endless possibilities.\
Learn all about it in the dedicated section:

{% content-ref url="broken-reference" %}
[Broken link](broken-reference)
{% endcontent-ref %}

[^1]: A Roblox font object created with `Font.new()`.
