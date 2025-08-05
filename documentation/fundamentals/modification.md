# Modification

You can modify a text frame after the initial creation, like this:

```lua
Text.Create(
	frame, -- Frame that already has text created within it.
	"This text has been modified!" -- New text.
)
```

You can even modify the customization after the creation, like this:

```lua
Text.Create(
	frame,
	"This text has been modified!",
	{ -- New customization (optional).
		Size = 12 -- Overwrite size.
		-- Everything else will stay like before!
	}
)
```

{% hint style="info" %}
It will keep all previous customization options, only overwriting with those you provide in the table.
{% endhint %}

{% hint style="success" %}
You can reset any of the customization options to the default by simply setting it to `false`.
{% endhint %}

