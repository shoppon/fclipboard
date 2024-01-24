import 'dart:convert';
import 'dart:math';

import 'package:fclipboard/entry_adding.dart';
import 'package:fclipboard/dao.dart';
import 'package:fclipboard/matcher.dart';
import 'package:fclipboard/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openapi/api.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';

import 'generated/l10n.dart';
import 'model.dart' as m;

class EntryListView extends StatefulWidget {
  EntryListView({
    Key? key,
    required this.filterNotifier,
    required this.entryNotifier,
  }) : super(key: key);

  final _entryFocusNode = FocusNode();
  final ValueNotifier<String> filterNotifier;
  final ValueNotifier<m.Entry?> entryNotifier;

  @override
  State<EntryListView> createState() => _EntryListViewState();
}

class _EntryListViewState extends State<EntryListView> {
  List<m.Entry> entries = [];

  int _preSelectedIndex = -1;
  int _curSelectedIndex = -1;

  final _dbHelper = DBHelper();
  final _matcher = Matcher(10);

  Offset _tapPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    RawKeyboard.instance.addListener(_handleKeyEvent);
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

  void _filterEntries(String searchText) async {
    if (searchText.contains("#category:")) {
      final category = searchText.split("#category:")[1].split(",")[0];
      final es = await _dbHelper.entries(categories: [category]);
      setState(() {
        entries.clear();
        entries.addAll(es);
      });
    } else {
      await loadEntries();
      widget.entryNotifier.value = m.Entry.empty();
      _curSelectedIndex = -1;
      _preSelectedIndex = -1;
      setState(() {
        final matches = _matcher.match(searchText);
        entries.clear();
        for (final match in matches) {
          entries.add(match);
        }
      });
    }
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
        } else {
          var subtitle = entry.subtitle;
          for (var p in entry.parameters) {
            if (p.required && p.initial.isEmpty) {
              return;
            }

            if (p.initial.isNotEmpty) {
              subtitle = subtitle.replaceAll(p.name, p.initial);
            }
          }
          Clipboard.setData(ClipboardData(text: subtitle));
        }
      }
    });
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.isAltPressed && isWindows() ||
          event.isMetaPressed && isMacOS() ||
          event.isControlPressed && isWeb()) {
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

  Future<void> loadEntries() async {
    final entries = await _dbHelper.entries();
    _matcher.reset(entries);
    setState(() {
      // get most used 10 entries
      entries.sort((a, b) => b.counter.compareTo(a.counter));
      this.entries = entries.sublist(0, min(10, entries.length));
    });
  }

  String _getTrailingText(int index) {
    if (isWindows()) {
      return 'alt+${index + 1}';
    } else if (isMacOS()) {
      return 'cmd+${index + 1}';
    } else if (isWeb()) {
      return 'ctrl+${index + 1}';
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
            content: Text(S.of(context).confirmDelete),
            actions: <Widget>[
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(S.of(context).cancel)),
              TextButton(
                onPressed: () async {
                  ProgressDialog pd = ProgressDialog(context: context);
                  pd.show(msg: S.of(context).loading);
                  final selected = entries[index];
                  // delete server entry
                  if (!await _deleteServerEntry(selected.uuid)) {
                    if (context.mounted) {
                      setState(() {
                        pd.close();
                        showToast(context, S.of(context).deleteFailed, true);
                        Navigator.of(context).pop();
                      });
                    }
                    return;
                  }

                  // delete entry
                  await _dbHelper.deleteEntry(selected.title).then((value) {
                    setState(() {
                      entries.removeAt(index);
                      pd.close();
                      showToast(context, S.of(context).deleteSuccess, false);
                      Navigator.of(context).pop();
                    });
                  });
                },
                child: Text(S.of(context).ok),
              )
            ],
          );
        });
  }

  Future<bool> _deleteServerEntry(String eid) async {
    try {
      final api = EntryApi(ApiClient(basePath: await loadServerAddr()));
      final email = loadUserEmail();
      await api.deleteEntry(email, eid);
      return true;
    } catch (e) {
      return false;
    }
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
      items: <PopupMenuEntry<int>>[
        PopupMenuItem(value: 0, child: Text(S.of(context).update)),
        PopupMenuItem(value: 1, child: Text(S.of(context).delete)),
        PopupMenuItem(value: 2, child: Text(S.of(context).share)),
      ],
    );
    // update
    if (selectedValue == 0 && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EntryAddingPage(entry: entries[index])),
      ).then((value) => loadEntries());
    }
    // delete
    if (selectedValue == 1 && context.mounted) {
      _deleteListItem(context, index);
    }
    // share
    if (selectedValue == 2) {
      final entry = entries[index];
      final decoded = base64Encode(utf8.encode(jsonEncode(entry.toJson())));
      Clipboard.setData(ClipboardData(text: decoded));
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
                  color: getColor(_curSelectedIndex, i),
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
                    onLongPress: () {
                      _selectItem(i);
                      _showOperateMenu(context, i);
                    },
                  ),
                ),
              );
            }));
  }
}
