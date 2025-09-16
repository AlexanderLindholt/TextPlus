---
icon: ballot
---

# Options

The options is a table, where you may provide any options you like.\
You are not required to provide all, or even any, as all options have defaults.

Example options:

```lua
Text.Create(
	frame,
	"This text is awesome!",
	{ -- Options (optional).
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

