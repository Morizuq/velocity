import 'package:flutter/material.dart';

/// Design tokens for border radius dimensions.
///
/// Ensures elements like cards, buttons, dialogs, and text fields have
/// consistent corners across light and dark interfaces.
class AppBorderRadius {
  AppBorderRadius._();

  /// Progress bar corner radius (3.0).
  static const double bar = 3.0;

  /// Small corner radius (4.0).
  static const double s = 4.0;

  /// Split bar corner radius (7.0).
  static const double splitBar = 7.0;

  /// Medium / Button / Input corner radius (8.0).
  static const double m = 8.0;
  static const double button = 8.0;
  static const double input = 8.0;

  /// Large / Avatar corner radius (12.0).
  static const double l = 12.0;
  static const double avatar = 12.0;

  /// Extra large / Card corner radius (16.0).
  static const double xl = 16.0;
  static const double card = 16.0;

  /// Hero / Modal Sheet corner radius (20.0).
  static const double hero = 20.0;
  static const double sheet = 20.0;

  /// Value to create fully circular surfaces.
  static const double circular = 9999.0;

  // BorderRadius objects

  /// Progress bar radius (3.0).
  static const BorderRadius allBar = BorderRadius.all(Radius.circular(bar));

  /// Small radius applied to all corners (4.0).
  static const BorderRadius allS = BorderRadius.all(Radius.circular(s));

  /// Split bar radius applied to all corners (7.0).
  static const BorderRadius allSplitBar = BorderRadius.all(
    Radius.circular(splitBar),
  );

  /// Medium radius applied to all corners (8.0).
  static const BorderRadius allM = BorderRadius.all(Radius.circular(m));

  /// Standard button radius (8.0).
  static const BorderRadius allButton = BorderRadius.all(
    Radius.circular(button),
  );

  /// Standard input textfield radius (8.0).
  static const BorderRadius allInput = BorderRadius.all(Radius.circular(input));

  /// Large radius applied to all corners (12.0).
  static const BorderRadius allL = BorderRadius.all(Radius.circular(l));

  /// Standard initial avatar radius (12.0).
  static const BorderRadius allAvatar = BorderRadius.all(
    Radius.circular(avatar),
  );

  /// Extra large / Card radius applied to all corners (16.0).
  static const BorderRadius allXL = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius allCard = BorderRadius.all(Radius.circular(card));

  /// Hero container radius applied to all corners (20.0).
  static const BorderRadius allHero = BorderRadius.all(Radius.circular(hero));

  /// Top corners radius for modal bottom sheets (20.0).
  static const BorderRadius topSheet = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );

  /// Circular radius applied to all corners.
  static const BorderRadius allCircular = BorderRadius.all(
    Radius.circular(circular),
  );

  /// Pill-style radius applied to all corners (equivalent to circular).
  static const BorderRadius pill = BorderRadius.all(Radius.circular(circular));
  static const BorderRadius allPill = pill;

  /// Radius applied only to the right corners (top-right and bottom-right).
  static const BorderRadius rightOnly = BorderRadius.only(
    topRight: Radius.circular(l),
    bottomRight: Radius.circular(l),
  );
}
