# Scale-size

There are six scale-size options, which are inputted in the customization:

* "RootX"
* "RootY"
* "RootXY"\
  ​
* "FrameX"
* "FrameY"
* "FrameXY"



Enabling scale-size will make `Size` a percentage of the root/frame size instead of a pixel amount.\
It will use the specified axis — for `XY` it will get the in-between of the two axis sizes.

{% hint style="info" %}
When using a\
\- ScreenGui: `Root` is the user's screen.\
\- SurfaceGui: `Root` is the SurfaceGui.
{% endhint %}



## Visualizing & calculating size (for root only)

You can easily find the `Size` that maintains the aspect ratio you are seeing in the studio viewport using the code snippets I've made for you.

Run the code for your GUI root in the command bar:

### ScreenGui

```lua
local scaleSize = "X" local textLabelSize = 14										local viewportSize = workspace.CurrentCamera.ViewportSize if scaleSize == "XY" then viewportSize = (viewportSize.X + viewportSize.Y)/2 else viewportSize = viewportSize[scaleSize] end warn(math.round(textLabelSize/viewportSize*100*1000)/1000)
```

### SurfaceGui

_Make sure to select your SurfaceGui before running._

{% code fullWidth="false" %}
```lua
local scaleSize = "X" local textLabelSize = 14										local surfaceGui = game.Selection:Get()[1] local adornee = surfaceGui.Adornee if not adornee then adornee = surfaceGui.Parent end local viewportSize = nil local face = surfaceGui.Face local pixelsPerStud = surfaceGui.PixelsPerStud local partSize = adornee.Size if face == Enum.NormalId.Front or face == Enum.NormalId.Back then viewportSize = Vector2.new(partSize.X*pixelsPerStud, partSize.Y*pixelsPerStud) elseif face == Enum.NormalId.Left or face == Enum.NormalId.Right then viewportSize = Vector2.new(partSize.Z*pixelsPerStud, partSize.Y*pixelsPerStud) else viewportSize = Vector2.new(partSize.X*pixelsPerStud, partSize.Z*pixelsPerStud) end if scaleSize == "XY" then viewportSize = (viewportSize.X + viewportSize.Y)/2 else viewportSize = viewportSize[scaleSize] end warn(math.round(textLabelSize/viewportSize*100*1000)/1000)
```
{% endcode %}

\
_Make sure to input your desired `ScaleSize` type/axis and the TextLabel's size._

It should print out a number in the `Output` window. This is what you want to input for the `Size` to maintain the aspect ratio you are seeing in studio.
