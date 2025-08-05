# Update

Every frame has this signal, which fires every time text is re-rendered inside the frame.\
The signal can be retrieved like this:

```lua
Text.GetUpdateSignal(frame)
```

{% hint style="info" %}
This is especially useful for detecting when the text is re-rendered by the dynamic mode.
{% endhint %}
