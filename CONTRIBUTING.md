# Contribution guide

## Getting started
### Guides & Docs
- [Vala Tutorial](https://wiki.gnome.org/Projects/Vala/Tutorial)
- [Vala Examples](https://wiki.gnome.org/Projects/Vala/Examples)
- [Valadoc](https://valadoc.org) - A documentation system for all popular Vala libraries.
- [Valadoc - Comment Markup](https://valadoc.org/markup.htm)
- [elementaryOS Developer Guide](https://elementary.io/docs/code/getting-started)
- [GNOME Human Interface Guidelines (HIG)](https://developer.gnome.org/hig/stable)
- [GTK.org](https://www.gtk.org) - Official Website
- [A Digital Guitar Tuner](https://arxiv.org/pdf/0912.0745.pdf) - Thoroughly describes a possible road of implementing an FFT based guitar tuner.

### Programs

- `gtk3-demo` - demonstrates how widgets GTK widgets work, with code samples in C.
- `gtk3-widget-factory` - showcases all GTK widgets and some of their interesting features.
- `gtk3-icon-browser` - showcases some default icons and their names that can be used with GTK.
- `devhelp` - offline documentation reader

**Note:** These usually come bundled with GTK development libraries.

## Recommended editors
1. [Visual Studio Code](https://code.visualstudio.com) - A robust text editor made with Electron.
2. [Vim](https://www.vim.org) - Terminal based text editor

### Recommended extensions for Visual Studio Code
- [Trailing Spaces](https://marketplace.visualstudio.com/items?itemName=shardulm94.trailing-spaces)
- [gettext](https://marketplace.visualstudio.com/items?itemName=mrorz.language-gettext)
- [Meson](https://marketplace.visualstudio.com/items?itemName=asabil.meson)
- [Vala Grammar](https://marketplace.visualstudio.com/items?itemName=philippejer.vala-grammar)
- [Todo Tree](https://marketplace.visualstudio.com/items?itemName=Gruntfuggly.todo-tree)


## Coding style

### 1. Identifiers
1. All identifiers should be given a meaningful, english name
2. Class name identifiers should be written in **UpperCamelCase**
3. Class members and local variables should be written in **snake_case**

### 2. Indentation and Spaces
1. 1 tab = 4 spaces
2. Always strip trailing spaces (if you are using VSCode, [Trailing Spaces](https://marketplace.visualstudio.com/items?itemName=shardulm94.trailing-spaces) extension can do this for you)

### 3. Brackets and Operators
1. Use [1TBS - One True Brace Style](https://en.wikipedia.org/wiki/Indentation_style#Variant:_1TBS_(OTBS))
2. Conditional statement and loop bodies (`if, while, for, etc.`)  should always be enclosed with curly brackets.
3. Operators should be separated with one space.
4. Method call operator **()** should always be separated with one space from the method name.

**Note:** when in doubt, look at the existing code and try to imitate its style :)

## Finally,
if you have read this entire thing, **welcome aboard! :)**