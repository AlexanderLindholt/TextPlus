---
icon: ballot
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

# Options

The options are provided in a table. You may provide any amount of options you like.\
Those not provided will fallback to their respective defaults.

Example:

<pre class="language-lua"><code class="lang-lua">Text.Create(
	frame,
	"This text is awesome!",
<strong>	{ -- Options (optional).
</strong><strong>		Size = 24,
</strong><strong>		Color = Color3.fromRGB(255, 255, 255),
</strong><strong>		XAlignment = "Center",
</strong><strong>		YAlignment = "Center"
</strong><strong>	}
</strong>)
</code></pre>





You can get the current options for a frame at any time like this:

```lua
Text.GetOptions(frame)
```

{% hint style="info" %}
The options received from the `GetOptions` function will always be valid, and will contain _all_ options except booleans set to `false` and those that aren’t mandatory.
{% endhint %}
