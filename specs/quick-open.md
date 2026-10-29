# Quick Open

Find a file in a chosen top-level folder by typing part of its path, and
open it in the markdown editor.

## Root folder

- The root folder is chosen with the Android system folder picker
  (`ACTION_OPEN_DOCUMENT_TREE`). The app takes a persisted read and write
  permission for the folder, which covers every file below it, so files
  found there can be opened, saved, added to recents and bound to widgets
  without picking them again.
- The folder is saved in shared preferences (`root_folder`) and kept
  across restarts. Choosing another folder replaces it.
- It can be chosen or changed from:
  - the **Folder** row on the markdown sub-app's first screen, and
  - the quick open page: its **Choose folder** button when no folder is
    set, and its **Change folder** action.

## Opening quick open

- A search button, "Quick open", is in the app bar of the launcher, the
  markdown sub-app's first screen and the editor.
- The quick open page takes the full screen, with the search field in the
  app bar, focused.
- Choosing a file opens it in the markdown editor above the launcher,
  replacing any editor already open, as a widget tap does. Back from the
  editor returns to the launcher.

## Listing files

- Files are listed recursively below the root folder, breadth first.
  Hidden files and folders (names starting with `.`) are skipped, and
  listing stops after 20,000 files.
- Listings are cached in memory for the session. Opening quick open shows
  the cached list straight away, lists the folder again in the background
  (shown by a progress bar) and updates the results when it finishes.
  **Refresh** lists it again on demand.
- A failed listing shows an error with a retry.
- Listing runs on its own background thread, so a large folder does not
  delay saves.

## Matching

Results are ranked by an fzf-style fuzzy match against each file's path
below the root folder (`work/meeting-notes.md`):

- The query is split on whitespace; every term must appear in the path in
  order, but not necessarily adjacent (`mtnt` matches `meeting-notes`).
  Terms can be in any order (`todo work` matches `work/todo.md`).
- Smart case: a term is case-insensitive unless it contains an uppercase
  letter.
- Among the ways a term can match, the best-scoring one is used. Matches
  score higher:

  - at the start of the path or of a path segment (after `/`),
  - at the start of a word (after `-`, `_`, `.` or a space),
  - on a camelCase hump,
  - in runs of adjacent characters, and
  - in the file name rather than the folders;

  and lower for each gap between matched characters.

- Ties go to recently opened files, then shorter paths, then alphabetical
  order. An empty query lists every file in that order.
- At most 100 results are shown. Matched characters are highlighted, with
  the file name as the title and its folder below.
- Submitting the search field opens the best match.
