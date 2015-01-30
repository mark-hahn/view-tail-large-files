# view-tail-large-files Atom editor package

View and tail files gigabytes long.  Great for logs.

----

**Viewing a one-gigabyte file with ten million lines of text ...**

  ![Animated GIF](https://github.com/mark-hahn/view-tail-large-files/blob/master/screenshots/gig.gif?raw=true)

----

VTLF (view-tail-large-files) allows you to open large text files in read-only mode directly in the Atom editor.  The file can be loaded from anywhere on your system, not just from the project tree. It will also allow you to tail a file as it grows with new lines appearing at the bottom.  

The package has been designed from the ground up to be expandable by plug-ins much like the Atom editor itself.  Plugins in the future will allow for features like searching by time, formatting logs into columns, viewing formatted CSV files, etc.

While VTLF is mainly used for logs, it can view any text file.

# Usage

Install via the usual `apm install view-tail-large-files` or using the packages section of settings.

Use the default key binding of `ctrl-alt-L` (`view-tail-large-files:open`) to select a file to open. You can navigate the file using the native browser keys such as `up`, `down`, `page-up`, `page-down`, `move-to-top`, and `move to bottom`.  Of course the scrollbars and mousewheel work as usual.  There are no cursors or selections until some plug-in provides them.

See the plugins section below for details of other features like tailing files.

# Copying Text

When you click anywhere in the text and drag the mouse, text will be selected and immediately copied to the clipboard.  Only lines can be selected at this time.

# Performance

A ram-based index of lines in the file is created when the file is opened and appended to as the file grows.  The index memory requirements are about 10% of the file size.  So a 100 MByte file requires abount 10 MBytes of memory. The index is created as fast as the file can be read, which is usually about 1 second per 50 MBytes which is 20 seconds for a gigabyte. The index allows true random-access to any line so jumping to a specific location appears to be instantaneous and scrolling is fast.

The only hard limit on file size is memory usage.  On my windows system I can open five copies of a gigabyte test file before Atom crashes.  Unfortunately there doesn't seem to be a way to avoid Chrome's rude behavior.  So save everything before attempting to load a few gigabytes.

# Plug-ins

Anyone who can develop a package for Atom can easily do the same for VTLF.  It uses one simple fileView object to control the viewing.  It also uses the new event-kit system.  The to-do list includes documenting the api but for now there are samples.  

Three plugins are provided in the base install.  These can be enabled/disabled in settings.

- File-picker: It may seem strange to see that the file picker for opening a file can be disabled.  This is possible because there are alternatives like the next plugin below.  If the file-picker is disabled then the VTLF activation time goes from 360ms to 160ms.  I haven't yet studied the cause of the slowdown.  The OS file picker couldn't be used because it is hard-wired to the project tree.  See file-picker usage instructions below.

- Auto-open:  This plugin causes files chosen from the project file tree to be be automatically opened by VTLF if the file is too large for Atom (> 2Mb).

- Tail: A file opened for tailing is initially scrolled to the bottom. New lines added to the open file appear at the bottom in real time.  The last line number displayed on the bottom will be underlined to indicate that tailing is happening.  If you manually scroll away from the bottom then tailing is paused until you scroll back down.  See next section for instructions to enable tailing.

# Settings ...
- Font Family: This is selectable differently from the normal settings because viewing files is different than editing source code.  The default is Courier.

- Font Size:  Size in pixels.  Defaults to 14.

- Select Plugins By File Path Regex: Plugins can be selectively applied based on matching a regex on the file path. This setting is a string with plugin names and regex strings separated by colons.  The default setting is `file-picker: auto-open: tail:\.log$`.  The file-picker and auto-open have no regex since they are not file path dependent, but they can be disabled by putting in the magic regex of `off` like `file-picker:off` or by deleting the option.  The tail plugin regex by default only enables tailing for files with the suffix `.log`. Change it to `.*` to enable tailing for all files.

# File Picker Usage

Open the file picker dialog using the `ctrl-alt-L` (`view-tail-large-files:open`) default key binding.

The custom file-picker allows opening files with directory navigation, picking recently used files, or directly entering a path.  There are several unique properties of the picker...

- The directory listing is broken into two boxes, one for nested directories and another for files.  The directories and files shown are the contents of the directory that is currently visible in the textbox above.

- When typing into the path textbox, the path is constantly checked for validity.  If the path is invalid a red highlight will show the invalid portion at the end.  If the path is used then the red part is ignored.

- When a recent file name is selected the path textbox shows the complete path.  This avoids ambiguity for duplicate file names.

- You may use the tab key to switch the selected input box, which is shown with a border.  But you may also just type control keys like up/down at any time no matter what input is selected.

# Future Plugins

Here are some ideas for new plug-ins. I will implement some of these myself but writing a VTLF plugin would increase your karma points immensely.

- Selection line to help viewing.
- Bookmarks.
- GOTO by date or "page" by time intervals like hours, minutes, or seconds.
- Find and highlight by search string.
- Format logs into columns.  Good for standard file formats or CSV files.
- Persistent indexes to speed up loading and retain highlights, bookmarks, etc.
- A zillion more

# Future Enhancements To Core
- reduce ram usage and speed up indexing (there is a known technique)
- reduce file-picker activation time
- support line lengths longer than 16,384 bytes
- write detailed plugin-authoring doc in wiki

# testing
- create spec tests
- test unicode

# bugs
- crash when opening binary files like pdf
- chrome crashes when to much ram is used

# License
Copyright Mark Hahn under the standard MIT license.  See LICENSE.md.
