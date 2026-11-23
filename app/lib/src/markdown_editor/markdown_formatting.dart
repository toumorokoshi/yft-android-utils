import 'dart:math' as math;

import 'package:flutter/services.dart';

/// A markdown formatting action that transforms a [TextEditingValue].
typedef MarkdownFormatAction = TextEditingValue Function(TextEditingValue);

final _headingPrefix = RegExp(r'^#{1,6}(?:\s+|$)');
final _checkboxPrefix = RegExp(r'^- \[[ xX]\](?:\s+|$)');
final _bulletPrefix = RegExp(r'^[-*+](?:\s+|$)');
final _quotePrefix = RegExp(r'^>(?:\s+|$)');

/// Toggles an ATX heading of [level] (1–6) on the selected line(s).
///
/// If the line already has the same heading level, the prefix is removed.
/// If it has a different heading level, that prefix is replaced.
TextEditingValue toggleHeading(TextEditingValue value, int level) {
  assert(level >= 1 && level <= 6);
  final prefix = '${'#' * level} ';
  return _transformSelectedLines(value, (line) {
    final match = _headingPrefix.firstMatch(line);
    if (match != null) {
      final existing = match.group(0)!;
      final rest = line.substring(match.end);
      // Treat exact level match (with or without trailing space) as a toggle off.
      if (existing.trimRight() == '#' * level) {
        return rest;
      }
      return '$prefix$rest';
    }
    return '$prefix$line';
  });
}

/// Toggles a markdown bullet list prefix (`- `) on the selected line(s).
TextEditingValue toggleBulletList(TextEditingValue value) {
  return _transformSelectedLines(value, (line) {
    final checkbox = _checkboxPrefix.firstMatch(line);
    if (checkbox != null) {
      return '- ${line.substring(checkbox.end)}';
    }
    final bullet = _bulletPrefix.firstMatch(line);
    if (bullet != null) {
      return line.substring(bullet.end);
    }
    return '- $line';
  });
}

/// Toggles a markdown task list prefix (`- [ ] `) on the selected line(s).
TextEditingValue toggleChecklist(TextEditingValue value) {
  return _transformSelectedLines(value, (line) {
    final checkbox = _checkboxPrefix.firstMatch(line);
    if (checkbox != null) {
      return line.substring(checkbox.end);
    }
    final bullet = _bulletPrefix.firstMatch(line);
    if (bullet != null) {
      return '- [ ] ${line.substring(bullet.end)}';
    }
    return '- [ ] $line';
  });
}

/// Toggles a markdown blockquote prefix (`> `) on the selected line(s).
TextEditingValue toggleBlockquote(TextEditingValue value) {
  return _transformSelectedLines(value, (line) {
    final match = _quotePrefix.firstMatch(line);
    if (match != null) {
      return line.substring(match.end);
    }
    return '> $line';
  });
}

/// Wraps or unwraps the selection with [marker] (e.g. `**`, `*`, `` ` ``).
///
/// With a collapsed cursor, inserts a pair of [marker]s and places the cursor
/// between them.
TextEditingValue toggleInlineWrap(TextEditingValue value, String marker) {
  final text = value.text;
  final selection = _normalizedSelection(value);
  final start = selection.start;
  final end = selection.end;

  if (start == end) {
    final newText =
        '${text.substring(0, start)}$marker$marker${text.substring(end)}';
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + marker.length),
    );
  }

  final selected = text.substring(start, end);
  final mLen = marker.length;

  // Unwrap if the markers sit just outside the selection.
  if (start >= mLen &&
      end + mLen <= text.length &&
      text.substring(start - mLen, start) == marker &&
      text.substring(end, end + mLen) == marker) {
    final newText =
        '${text.substring(0, start - mLen)}$selected${text.substring(end + mLen)}';
    return TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: start - mLen,
        extentOffset: end - mLen,
      ),
    );
  }

  // Unwrap if the selection itself starts and ends with the markers.
  if (selected.length >= mLen * 2 &&
      selected.startsWith(marker) &&
      selected.endsWith(marker)) {
    final inner = selected.substring(mLen, selected.length - mLen);
    final newText = '${text.substring(0, start)}$inner${text.substring(end)}';
    return TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: start,
        extentOffset: start + inner.length,
      ),
    );
  }

  final newText =
      '${text.substring(0, start)}$marker$selected$marker${text.substring(end)}';
  return TextEditingValue(
    text: newText,
    selection: TextSelection(
      baseOffset: start + mLen,
      extentOffset: end + mLen,
    ),
  );
}

/// Inserts a markdown link `[selected](url)` or `[](url)` at the selection.
TextEditingValue insertLink(TextEditingValue value) {
  final text = value.text;
  final selection = _normalizedSelection(value);
  final start = selection.start;
  final end = selection.end;

  if (start == end) {
    final newText = '${text.substring(0, start)}[](url)${text.substring(end)}';
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + 1),
    );
  }

  final label = text.substring(start, end);
  final inserted = '[$label](url)';
  final newText = '${text.substring(0, start)}$inserted${text.substring(end)}';
  final urlStart = start + label.length + 3;
  return TextEditingValue(
    text: newText,
    selection: TextSelection(baseOffset: urlStart, extentOffset: urlStart + 3),
  );
}

TextSelection _normalizedSelection(TextEditingValue value) {
  final sel = value.selection;
  if (!sel.isValid) {
    return TextSelection.collapsed(offset: value.text.length);
  }
  return TextSelection(
    baseOffset: math.min(sel.start, value.text.length),
    extentOffset: math.min(sel.end, value.text.length),
  );
}

TextEditingValue _transformSelectedLines(
  TextEditingValue value,
  String Function(String line) transform,
) {
  final text = value.text;
  final selection = _normalizedSelection(value);
  final selStart = selection.start;
  final selEnd = selection.end;

  // Find the start of the first selected line.
  final blockStart = selStart == 0
      ? 0
      : text.lastIndexOf('\n', selStart - 1) + 1;

  // If selection ends right at a newline after a non-empty range, don't include
  // the following line unless the selection is collapsed on that newline.
  final effectiveEnd =
      selEnd > selStart && selEnd > 0 && text[selEnd - 1] == '\n'
      ? selEnd - 1
      : selEnd;
  final nextNewline = text.indexOf('\n', effectiveEnd);
  final blockEnd = nextNewline == -1 ? text.length : nextNewline;

  final block = text.substring(blockStart, blockEnd);
  final lines = block.split('\n');
  final updatedLines = <String>[];

  var newSelStart = selStart;
  var newSelEnd = selEnd;
  var lineOffset = blockStart;
  var priorDelta = 0;

  for (var i = 0; i < lines.length; i++) {
    final oldLine = lines[i];
    final newLine = transform(oldLine);
    updatedLines.add(newLine);

    final delta = newLine.length - oldLine.length;
    final oldLineEnd = lineOffset + oldLine.length;

    if (i == 0) {
      newSelStart = math.max(lineOffset, selStart + delta);
    }
    if (selEnd > oldLineEnd) {
      newSelEnd += delta;
    } else if (selEnd >= lineOffset) {
      newSelEnd = math.max(lineOffset + priorDelta, newSelEnd + delta);
    }

    priorDelta += delta;
    lineOffset = oldLineEnd + 1; // +1 for '\n'
  }

  final newBlock = updatedLines.join('\n');
  final newText =
      '${text.substring(0, blockStart)}$newBlock${text.substring(blockEnd)}';

  final clampedStart = newSelStart.clamp(0, newText.length);
  final clampedEnd = newSelEnd.clamp(clampedStart, newText.length);

  return TextEditingValue(
    text: newText,
    selection: selStart == selEnd
        ? TextSelection.collapsed(offset: clampedStart)
        : TextSelection(baseOffset: clampedStart, extentOffset: clampedEnd),
  );
}
