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

# Fonts

One of these datatypes is expected:

* A [`Font`](#user-content-fn-1)[^1] object.
* A custom font data table.

You can use Roblox’s officially supported fonts like this:

```lua
Text.Create(
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

You can find all the built-in Roblox fonts [here](https://create.roblox.com/docs/reference/engine/datatypes/Font).

Simply copy the asset id from the font list and paste it into the `Font` object’s `Family` field.

### Creator store fonts

Alternatively, browse many more fonts at the [creator store](https://create.roblox.com/store/fonts).

Click `Get Font`.\
Create a `TextLabel` in Roblox Studio and apply the font to it.\
Make sure you have the `TextLabel` selected, then run this in the command bar:

```lua
print(game.Selection:Get()[1].FontFace.Family)
```

It will output the asset id you need.\
Simply copy-and-paste it into the `Font` object’s `Family` field.

***

### Custom fonts

Learn all about it in the dedicated section:

{% content-ref url="https://app.gitbook.com/s/Bw4wVemrevDavfaAr2MQ/custom-fonts" %}
[Custom fonts](https://app.gitbook.com/s/Bw4wVemrevDavfaAr2MQ/custom-fonts)
{% endcontent-ref %}

[^1]: A Roblox font object created with `Font.new()`.
