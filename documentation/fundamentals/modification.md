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

# Modification

You can modify text after the initial creation, like this:

```lua
Text.Create(
	frame, -- Frame that already has text created within it.
	"This text has been modified!" -- New text.
)
```

You can even modify the options, like this:

```lua
Text.Create(
	frame,
	"This text has been modified!",
	{ -- New options (optional).
		Size = 12 -- Overwrite size.
		-- Everything else will stay like before!
	}
)
```

{% hint style="info" %}
It will retain all previous options, only overwriting with those you provide as new ones.
{% endhint %}

{% hint style="success" %}
You can reset any of the options to the default by simply setting it to `false`.
{% endhint %}

