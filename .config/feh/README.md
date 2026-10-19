Press **Ctrl+C** (or **1**) in feh to copy the current image to the X11
clipboard as PNG. The image stays open. This copies the source image with
EXIF orientation applied, without feh's zoom or temporary rotations.

Requires `xclip` and `python3-pil`. Provisioning links this directory to
`~/.config/feh` and the helper through `~/scripts`.
