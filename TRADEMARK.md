# Trademark and branding

The Spella **source code** is released under the [MIT License](LICENSE). Use
it, fork it, learn from it, ship things with it.

The Spella **name, logo and app icon** are not part of that grant. The files in
[`assets/branding/`](assets/branding/) — `spella_icon.png`,
`spella_icon_1024.png`, `spella_icon_1024_ink.png`,
`spella_icon_adaptive_fg.png`, `spella_logo_horizontal.png` and
`spella_logo_horizontal_readme.png` — remain the author's marks and are
excluded from the MIT licence.

This is the same split used by many open-source projects: the code is free, the
identity isn't, so that a user downloading something called "Spella" knows what
they're getting.

## What that means in practice

**You may, without asking:**

- Fork, modify, redistribute and commercialise the code under MIT.
- Keep the branding assets in your fork while you work on it, and open pull
  requests back here.
- Use the name to refer to this project — "built on Spella", "a Spella fork",
  writing about it, linking to it.

**Please don't, without asking:**

- Publish a fork to an app store, or distribute it to end users, under the name
  **Spella** or with the Spella icon.
- Use the name or logo in a way that suggests this project endorses yours.

If you're shipping a fork, give it its own name and icon. Replacing the icon is
a one-line change in [`pubspec.yaml`](pubspec.yaml) under
`flutter_launcher_icons`, followed by:

```bash
dart run flutter_launcher_icons
```

Want to do something this doesn't cover? Open a
[discussion](https://github.com/Sthabiso10/Spella/discussions) and ask — the
answer is usually yes.
