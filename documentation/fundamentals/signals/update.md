---
layout:
  width: default
  title:
    visible: true
  description:
    visible: false
  tableOfContents:
    visible: false
  outline:
    visible: true
  pagination:
    visible: true
  metadata:
    visible: true
---

# Update

Every frame has this signal, which fires every time text is rendered in the frame.\
The signal can be retrieved like this:

```lua
Text.GetUpdateSignal(frame)
```
