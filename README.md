# Incsearch

Minimalistic (yet powerful) incremental search package for Atom editor, allowing faster movement across your text. And since a picture is worth a thousand words:

![incsearch-usage](https://cloud.githubusercontent.com/assets/235075/12428826/c221500e-bf08-11e5-98ce-d57e60bae242.gif)

And a little more text for those, who were not convinced. Currently incremental search have following features packed:

* Highlight all matches
* Search by regular expression
* Case sensitive search

Pretty straightforward and obvious, but I'll be glad to hear your proposals!

## Keymap

| Key binding | Command | Description |
|-------------|---------|-------------|
| <div style="width: 115px"><kbd>Ctrl</kbd> + <kbd>I</kbd></div> | `incsearch:toggle` | Toggles incremental search panel, showing it, or focusing if it's already visible and your cursor is in the editor |

Following key bindings will work only when cursor is in the search field, allowing faster option switching and traversing results.

| Key binding | Command | Description |
|-------------|---------|-------------|
| <div style="width: 115px"><kbd>F3</kbd></div> | `incsearch:goto:next-match` | Moves cursor to next match |
| <div style="width: 115px"><kbd>Shift</kbd> + <kbd>F3</kbd></div> | `incsearch:goto:prev-match` | Moves cursor to previous match |
| <div style="width: 115px"><kbd>Ctrl</kbd> + <kbd>A</kbd></div> | `incsearch:toggle-option:highlight_all` | Toggles "Highlight all" option, which will mark all of the matches, instead of a current one |
| <div style="width: 115px"><kbd>Ctrl</kbd> + <kbd>R</kbd></div> | `incsearch:toggle-option:regex` | Toggles "Search by regular expression" option, which will allow searching by regular expression |
| <div style="width: 115px"><kbd>Ctrl</kbd> + <kbd>S</kbd></div> | `incsearch:toggle-option:case_sensitive` | Toggles "Case sensitive" option, which will allow case sensitive search |

While in search field you can decide how you will return to editing your text. If you press <kbd>Enter</kbd> - search panel will be closed and current match will be selected in editor. If you press <kbd>Escape</kbd> - search panel will also be closed, but no selection will be made, leaving cursor just before last match.

## Styling

Currently, `@input-background-color` color is used for non-active match and `@input-background-color` and `@text-color-warning` is used for active match (background and border color respectively).

## Customization

If you're willing to customize plugin behaviour or visuals - feel free to do so. You can style matches with following CSS (just put it in your stylesheet and modify as you wish):

```LESS
atom-text-editor .incsearch-highlight,
atom-text-editor::shadow .incsearch-highlight {
  .region {
    border: 1px solid @input-background-color;
    border-radius: @component-border-radius;
    background: @input-background-color;
  }
}

atom-text-editor .incsearch-current,
atom-text-editor::shadow .incsearch-current {
  .region {
    border: 1px solid @text-color-warning;
    border-radius: @component-border-radius;
    background: @input-background-color;
  }
}
```

## Contact me

If you're missing any functionality or have found a bug - please let me know through issues or pull request, I'll be glad to help!
