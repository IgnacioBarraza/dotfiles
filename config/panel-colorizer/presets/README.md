# Panel Colorizer presets

Applied by `scripts/panel_setup.sh` over D-Bus, and by hand with `panel-preset`.

Both start from Panel Colorizer 8's own schema rather than from one of its
shipped presets: the shipped ones predate several keys the widget now writes,
and loading one leaves those keys at whatever the widget defaults to.

`Nach0_0` hides the panel background and gives every widget its own rounded
island: radius 10, 12px apart, blurred behind.

It is the only preset here on purpose. A second one for maximised windows was
tried and removed: it flattened the islands, which is the very thing the look
exists to avoid, and since a maximised window is the normal state it was what
showed almost all of the time.

`spacing` is what separates the islands, not `margin`. At the shipped default
of 4 they touch and the row reads as one continuous bar, which is the whole
thing the look is trying to avoid. No preset that ships with the widget sets a
horizontal margin, so none of them separate the islands on their own.

`blurBehind` needs the C++ plugin, which `install_panel_colorizer` builds. From
the KDE Store the widget installs without it and the key does nothing.

`configure_colorizer_autoloading` switches the widget's automatic preset
loading off. Left on it reloads a preset on every start from rules of its own -
a fresh install had `floating` bound to a shipped preset - and that reload wins:
whatever was applied is replaced a moment later with nothing to say why. It also
resets `backgroundColor.alpha` to 1 whatever this file says, which makes the
islands opaque and hides the blur, so the alpha is applied afterwards by
`apply_colorizer_translucency` instead of living here.
