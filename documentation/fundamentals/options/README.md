---
icon: ballot
---

# Options

The customization works with a table, where you can provide any customizations you want.\
You don't have to provide all, or even any, because they all have defaults.

You use it like this:

```lua
Text.Create(
	frame,
	"This text is awesome!",
	{ -- Customization (optional).
		Size = 24,
		Color = Color3.fromRGB(255, 255, 255),
		XAlignment = "Center",
		YAlignment = "Center"
	}
)
```





You can get the current options for a frame at any time like this:

```lua
Text.GetOptions(frame)
```

{% hint style="info" %}
The options received from the `GetOptions` function will always be valid, and will contain _all_ options except booleans set to `false` and those that are optional.
{% endhint %}

