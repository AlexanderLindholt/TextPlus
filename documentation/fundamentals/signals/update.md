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
  tags:
    visible: true
  actions:
    visible: true
---

# Update

All text frames have this signal, which fires every time text is rendered in the frame.\
The signal can be retrieved like this:

```lua
Text.GetUpdateSignal(frame) -- Returns a signal created with your chosen library.
```

