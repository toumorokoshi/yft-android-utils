# Markdown Editor

A sub-app that edits one markdown file on the device, saving as you type.

## Files

- Files are chosen with the Android system file picker (the Storage Access
  Framework), so any provider works: local storage, SD cards, and synced
  folders whose app exposes a document provider. No storage permission is
  requested.
- The app takes a persisted read and write permission for each chosen
  file, so it can reopen the file after a restart or from a widget.
- The first screen has:
  - **Open file**: pick an existing file. Any type can be picked, since
    providers report markdown under different MIME types.
  - **New file**: create a file, named `notes.md` by default, with the
    system "save as" picker.
  - **Recent**: the last 10 files opened, newest first. Tapping one opens
    it.

## Editing

- The editor shows the file's text in a full-screen, monospace text field.
- Edits are saved 750 ms after the last keystroke, when the app is hidden,
  and when the editor is closed. Writes are queued, so they reach the file
  in order, and a write replaces the whole file.
- The app bar shows the file name and the save status: loading, editing,
  saving, saved, or an error. A failed read offers a retry; a failed save
  is retried on the next edit.
- A toggle switches between the editor and a rendered, selectable preview
  (`flutter_markdown_plus`).

## Home screen widget

- A 1x1 widget, "Markdown file", opens one file in the editor.
- Placing the widget opens the system file picker; the chosen file is
  bound to that widget. Cancelling the picker removes the widget. On
  Android 12 and later the widget can be reconfigured to another file.
- The widget shows a document icon and the file name.
- Tapping it opens the app straight into the editor for that file, with
  the launcher behind it, replacing any editor already open.
- The app only opens files it holds a persisted permission for, so other
  apps cannot use the widget's intent to make it write to their files.
