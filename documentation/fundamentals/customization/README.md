---
icon: fill-drip
---

# Customization

The customization works with a table, where you can provide any customizations you want.\
You don't have to provide all, or even any, because they all have defaults.

You use it like this:

```lua
TextPlus.Create(
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





You can get the current customization for a frame at any time like this:

```lua
TextPlus.GetCustomization(frame)
```

{% hint style="info" %}
The customization received from the `GetCustomization` function will always be valid, and will contain all customization options except booleans set to `false` and those that are optional.
{% endhint %}

