# Line breaks

You can manually break lines using just strings.\
There are two ways to do this.

{% tabs %}
{% tab title="Line-break symbol" %}
You can use `\n` to break to the next line at any place.\
`\n` will not be shown in the text.

{% hint style="warning" %}
Not a `/` (slash) but a `\` (backslash).
{% endhint %}

Example:

```lua
"First line\nSecond line"
```
{% endtab %}

{% tab title="Multiline strings" %}
Using `[[]]` instead of `""` will allow you to create a string that takes up multiple lines.\
You simply make an actual line break, and it will work.

Example:

```lua
[[First line
Second line]]
```
{% endtab %}
{% endtabs %}
