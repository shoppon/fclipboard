import 'dart:io';
import 'dart:math';

import 'package:fclipboard/adding_entry.dart';
import 'package:fclipboard/dao.dart';
import 'package:fclipboard/flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fclipboard/matcher.dart';
import 'package:fclipboard/model.dart';
import 'package:fclipboard/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EntryListView extends StatefulWidget {
  EntryListView({
    Key? key,
    required this.filterNotifier,
    required this.entryNotifier,
  }) : super(key: key);

  final _entryFocusNode = FocusNode();
  final ValueNotifier<String> filterNotifier;
  final ValueNotifier<Entry?> entryNotifier;

  @override
  State<EntryListView> createState() => _EntryListViewState();
}

class _EntryListViewState extends State<EntryListView> {
  List<Entry> entries = [];

  int _preSelectedIndex = -1;
  int _curSelectedIndex = 0;

  final _dbHelper = DBHelper();
  final _matcher = Matcher(10);

  Offset _tapPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    RawKeyboard.instance.addListener(_handleKeyEvent);
    loadEntries();
    widget.filterNotifier.addListener(() {
      _filterEntries(widget.filterNotifier.value);
    });
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(_handleKeyEvent);
    widget.filterNotifier.dispose();
    super.dispose();
  }

  void _filterEntries(String searchText) {
    setState(() {
      final searchTexts = searchText.split(' ');
      final matches = _matcher.match(searchTexts[0]);
      entries.clear();
      for (final match in matches) {
        entries.add(match);
      }
      _setSelectedIndex(0);
    });
  }

  void _setSelectedIndex(int index) {
    setState(() {
      _preSelectedIndex = _curSelectedIndex;
      _curSelectedIndex = index;
      if (_preSelectedIndex != _curSelectedIndex) {
        widget.entryNotifier.value = entries[_curSelectedIndex];

        final entry = entries[_curSelectedIndex];
        if (entry.parameters.isEmpty) {
          Clipboard.setData(ClipboardData(text: entry.subtitle));
        }
      }
    });
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.isAltPressed && Platform.isWindows ||
          event.isMetaPressed && Platform.isMacOS) {
        final logicalKey = event.logicalKey.keyLabel;
        int number = logicalKey.codeUnitAt(0) - 49;
        if (number >= 0 && number <= 9) {
          _setSelectedIndex(number);
        }
      }
      if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
        _setSelectedIndex(_curSelectedIndex);
      }
      if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
        setState(() {
          _setSelectedIndex((_curSelectedIndex + 1) % entries.length);
        });
      }
      if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
        setState(() {
          _setSelectedIndex((_curSelectedIndex - 1) % entries.length);
        });
      }
    }
  }

  void loadEntries() async {
    final entries = await _dbHelper.entries(null);
    _matcher.reset(entries);
    setState(() {
      // get most used 10 entries
      entries.sort((a, b) => b.counter.compareTo(a.counter));
      this.entries = entries.sublist(0, min(10, entries.length));
    });
  }

  String _getTrailingText(int index) {
    if (Platform.isWindows) {
      return 'alt+${index + 1}';
    } else if (Platform.isMacOS) {
      return 'cmd+${index + 1}';
    } else {
      return '';
    }
  }

  void _selectItem(int index) async {
    await _dbHelper.incEntryCounter(entries[index].title);
    setState(() {
      if (entries.length > index) {
        _setSelectedIndex(index);
      }
    });
  }

  void _deleteListItem(BuildContext context, int index) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          var title = 'Delete ${entries[index].title}';
          return AlertDialog(
            title: Text(title),
            content: Text(AppLocalizations.of(context).confirmDelete),
            actions: <Widget>[
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(AppLocalizations.of(context).cancel)),
              TextButton(
                onPressed: () {
                  // delete entry
                  _dbHelper.deleteEntry(entries[index].title).then((value) {
                    setState(() {
                      entries.removeAt(index);
                    });
                    showToast(context,
                        AppLocalizations.of(context).deleteSuccess, false);
                  });
                  Navigator.of(context).pop();
                },
                child: Text(AppLocalizations.of(context).ok),
              )
            ],
          );
        });
  }

  _getColor(i) {
    return _curSelectedIndex == i
        ? const Color.fromARGB(255, 199, 226, 248)
        : null;
  }

  void _showOperateMenu(BuildContext context, int index) async {
    final RelativeRect position = RelativeRect.fromLTRB(
      _tapPosition.dx,
      _tapPosition.dy,
      _tapPosition.dx + 40,
      _tapPosition.dy + 40,
    );
    int? selectedValue = await showMenu(
      context: context,
      position: position,
      items: <PopupMenuEntry<int>[
        PopupMenuItem(
            value: 0,
            child: Text(AppLocalizations.of(context).update)),
        PopupMenuItem(
            value: 1,
            child: Text(AppLocalizations.of(context).delete)),
      ],
    );
    if (selectedValue == 0 && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EntryAddingPage(entry: entries[index])),
      ).then((value) => loadEntries());
    }
    if (selectedValue == 1 && context.mounted) {
      _deleteListItem(context, index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
        focusNode: widget._entryFocusNode,
        child: ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, i) {
              return GestureDetector(
                onTapDown: (details) {
                  _tapPosition = details.globalPosition;
                },
                child: Container(
                  color: _getColor(i),
                  child: ListTile(
                    leading: InkWell(
                      child: Text(
                        entries[i].icon,
                        style: const TextStyle(fontSize: 32.0),
                      ),
                    ),
                    title: Text(entries[i].title),
                    subtitle: Text(entries[i].subtitle),
                    trailing: Text(_getTrailingText(i)),
                    selected: _curSelectedIndex == i,
                    onTap: () {
                      _selectItem(i);
                    },
                    onLongPress: () async {
                       _selectItem(i);
                       _showOperateMenu(context, i);
                    },
                  ),
                ),
              );
            }));
  }
}
