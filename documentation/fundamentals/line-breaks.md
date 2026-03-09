# Line breaks

You can manually break lines very easily.\
There are two simple ways to do this:

{% tabs %}
{% tab title="Line-break symbol" %}
You can use `\n` to break to the next line at any place.\
`\n` will not be shown in the text.

Example:

```lua
"First line\nSecond line"
```

{% hint style="warning" %}
Not a `/` (slash) but a `\` (backslash).
{% endhint %}
{% endtab %}

{% tab title="Multiline strings" %}
Using `[[]]` instead of `""` will allow you to create a string that spans multiple lines.\
You simply make an actual line break and it will work.

Example:

```lua
[[First line
Second line]]
```
{% endtab %}
{% endtabs %}
