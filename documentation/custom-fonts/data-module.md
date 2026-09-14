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

# Data module

{% stepper %}
{% step %}
### Create module

Create a new module and name it whatever you want — `Fonts` is recommended.
{% endstep %}

{% step %}
### Tag module

Give the module the [tag](https://create.roblox.com/docs/studio/properties#instance-tags) `Fonts`, so that Text+ can identify it.
{% endstep %}

{% step %}
### Module content

The module should return a table, like this:

```lua
return {
	
}
```
{% endstep %}
{% endstepper %}
