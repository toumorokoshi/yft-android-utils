import 'dart:math';

import 'package:flutter/services.dart';

final _headingPrefix = RegExp(r'^(#{1,6})( +|$)');

/// Toggles or sets an ATX markdown heading of [level] (1–6) on the line
/// containing the selection in [value].
///
/// If the line already has a heading of [level], its `# ` prefix is removed.
/// If it has a different heading level, the prefix is replaced. Otherwise,
/// `'#' * level + ' '` is inserted at the start of the line.
///
/// When [value.selection] is invalid (for example, before the editor is
/// focused), the cursor is treated as being at the end of [value.text].
TextEditingValue applyHeading(TextEditingValue value, int level) {
  RangeError.checkValueInInterval(level, 1, 6, 'level');

  final text = value.text;
  final rawSelection = value.selection.isValid
      ? value.selection
      : TextSelection.collapsed(offset: text.length);

  final anchor = rawSelection.start.clamp(0, text.length);
  final prevNewline = anchor == 0 ? -1 : text.lastIndexOf('\n', anchor - 1);
  final lineStart = prevNewline + 1;
  final nextNewline = text.indexOf('\n', anchor);
  final lineEnd = nextNewline == -1 ? text.length : nextNewline;

  final line = text.substring(lineStart, lineEnd);
  final match = _headingPrefix.firstMatch(line);

  final String replacement;
  final int oldPrefixLength;
  if (match != null) {
    oldPrefixLength = match.group(0)!.length;
    final currentLevel = match.group(1)!.length;
    replacement = currentLevel == level ? '' : '${'#' * level} ';
  } else {
    oldPrefixLength = 0;
    replacement = '${'#' * level} ';
  }

  final newText = text.replaceRange(
    lineStart,
    lineStart + oldPrefixLength,
    replacement,
  );
  final delta = replacement.length - oldPrefixLength;
  final newLineEnd = lineEnd + delta;

  int shiftOffset(int offset) {
    if (offset < lineStart) return offset;
    if (offset <= lineEnd) {
      return max(lineStart, min(newLineEnd, offset + delta));
    }
    return offset + delta;
  }

  return TextEditingValue(
    text: newText,
    selection: TextSelection(
      baseOffset: shiftOffset(rawSelection.baseOffset),
      extentOffset: shiftOffset(rawSelection.extentOffset),
      affinity: rawSelection.affinity,
      isDirectional: rawSelection.isDirectional,
    ),
  );
}
