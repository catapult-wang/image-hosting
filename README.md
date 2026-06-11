# Image Hosting

Static image hosting repository served by GitHub Pages.

## Structure

```text
images/
  daniel-dennett/
    from-bacteria-to-bach-and-back/
```

## URL Pattern

```text
https://catapult-wang.github.io/image-hosting/images/daniel-dennett/from-bacteria-to-bach-and-back/<filename>
```

Example:

```text
https://catapult-wang.github.io/image-hosting/images/daniel-dennett/from-bacteria-to-bach-and-back/f1-1.jpg
```

## Publish More Images

From this repository:

```powershell
.\scripts\publish-images.ps1 -Source "D:\path\to\images" -Destination "daniel-dennett/from-bacteria-to-bach-and-back" -Flatten
```

Use `-Flatten` when every image filename is unique and you want a clean URL. Omit it to preserve the local subfolder structure.
