# view-tail-large-files Atom editor package

View and tail files gigabytes long.  Great for logs.

VTLF (view-tail-large-files) allows you to open large text files in read-only mode directly in the Atom editor.  It will also allow you to tail a file as it grows  with new lines appearing at the bottom.  The package has been designed from the ground up to be expandable by plug-ins much like the Atom editor.


# Usage

Install via the usual `apm install view-tail-large-files` or using the packages section of settings.

The base version available now requires no special key bindings. Navigating the file uses the normal browser keys such as `page-up`, `page-down`, `move-to-top`, and `move to bottom`.  Of course the scrollbars work as usual.  Until some plug-in needs it there is no cursor or selections

# Performance

An ram-based index of lines in the file is created when the file is opened and appended to as the file grows.  The index memory requirements are about 10% of the file size.  So a 100 MByte file requires abount 10 MBytes of memory. The index is created as fast as the file can be read, which is usually about 10 to 20 seconds per gigabyte. The index allows true random-access to any line so jumping to a specific location appears to be instantaneous.

# Plug-ins

Just like Atom itself, VTLF was written with minimal features and architected so that features can be easily added.  The built-in capability is to index the file, load the lines into the pane, and support scrolling.  The tailing feature is implemented as a plug-in.   Anyone who can develop a package for Atom can easily do the same for VTLF.

Here are some ideas for new plug-ins. I will implement some of these myself but helping create these would increase your karma points immensely.

- Selection line to help keep track of lines
- Bookmarks


bugs:
  going away from tab breaks tailing
  double progress showing
  

# limitations

- If you expand the pane the text lines won't expand until you scroll.
- Line length must be under 16,384 bytes.