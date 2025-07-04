# Font to XML

## Font generation tool

We're going to be using [SnowB](https://snowb.org/) to generate the necessary font files.\
It's a free, simple bitmap font generation website.

## Character selection

You'll have to specify which characters you want to include in your custom font.\
This is done at the `Glyphs` section in the top-left corner.

By default, there should be all the characters you'll need.\
But it's crucial you get rid of the `№` character, because it is not supported.

If you're going to be using any more characters, feel free to add them.\
But you can use only [ASCII characters](https://www.ascii-code.com/).

## Font settings

Head over to the `Font` section, located right below `Glyphs`.

Get a `.ttf` or `.otf` file (a font file), whether it's one of your own or one you found online.\
Press `ADD FONT FILE`, and select your font file.

Set `Font Size` to your largest intended use case.

{% hint style="warning" %}
Try to avoid extreme size values like 500px unless absolutely necessary, as images have to be replicated from server to client.
{% endhint %}

## Fill settings

Head over to the `Fill` section, located in the top-right corner.

Set `Color` to pure white (255, 255, 255, 100).

{% hint style="success" %}
A pure white color will actually simply keep your original font color.\
If your font file is pure white too, you can be assured that the color you apply when rendering will be identical to the outcome.
{% endhint %}

## Export the files

Click `Export` in the top bar.\
Input a `File Name` for your font.\
For the `Export Type` select the `.fnt (BMFont XML)` option.

Press `Save` in the bottom-right corner of the pop-up.\
It should save a `.fnt` and a `.png` file.
