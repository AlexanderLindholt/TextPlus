# Font to XML

{% stepper %}
{% step %}
### Visit font generation website

Head over to [snowb.org](https://snowb.org/), where we're going to generate the necessary font files.\
It's a free, simple bitmap font generation website.
{% endstep %}

{% step %}
### Select characters

You'll have to specify which characters you want to include in your font.\
This is done in the `Glyphs` section in the top-left corner.

There's often already all the characters you need by default.\
But feel free to add any extra characters you desire!
{% endstep %}

{% step %}
### Font settings

Head over to the `Font` section, located right below `Glyphs`.

Get a `.ttf` or `.otf` font file, whether it's one of your own or one you found online.\
Press `ADD FONT FILE`, and select your file.

Set `Font Size` to your largest intended use case.

{% hint style="warning" %}
Try to avoid extreme size values like 500px unless absolutely necessary, since images have to be sent from the server to the clients.
{% endhint %}
{% endstep %}

{% step %}
### Fill settings

Head over to the `Fill` section, located in the top-right corner.

Set `Color` to pure white (255, 255, 255, 100).

{% hint style="success" %}
A pure white color will mean leaving your original font color untouched.\
It may also be beneficial.&#x20;
{% endhint %}
{% endstep %}

{% step %}
### Generate and export files

Click `Export` in the top bar.\
Input a `File Name` for your font.\
For the `Export Type` select the `.fnt (BMFont XML)` option.

Press `Save` in the bottom-right corner of the pop-up.\
It should save a `.fnt` and a `.png` file.
{% endstep %}
{% endstepper %}
