/// The palette slot a habit is painted with.
///
/// The domain deliberately stores a *slot* rather than a raw ARGB value. The
/// concrete color depends on whether the app is rendering against a light or a
/// dark surface, and picking the right step for each is the presentation
/// layer's job — see `HabitPalette`. Storing the resolved color instead would
/// freeze a habit into whichever theme was active when it was created.
///
/// Keeping this an enum also keeps `dart:ui` out of the domain layer.
///
/// **The declaration order is meaningful.** It is the validated categorical
/// order: adjacent slots are guaranteed to stay distinguishable under
/// color-vision deficiency in both themes. New habits should therefore default
/// to the next unused slot in this order rather than to an arbitrary one.
enum HabitColorSlot { blue, orange, aqua, yellow, magenta, green, violet, red }
