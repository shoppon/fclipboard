import 'package:fclipboard/cloud_utils.dart';
import 'package:fclipboard/utils.dart';
import 'package:flutter/material.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';

import 'dao.dart';
import 'generated/l10n.dart';
import 'model.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({Key? key}) : super(key: key);

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final _dbHelper = DBHelper();
  List<Category> categories = [];
  List<Entry> entries = [];

  int _curSelectedIndex = -1;

  Offset _tapPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    final es = await _dbHelper.entries();
    final cs = await _dbHelper.categories();
    setState(() {
      entries = es;
      categories = cs;
    });
  }

  int calculateCount(int cid) {
    int count = 0;
    for (var entry in entries) {
      if (entry.categoryId == cid) {
        count++;
      }
    }
    return count;
  }

  int calculateUsage(int cid) {
    int count = 0;
    for (var entry in entries) {
      if (entry.categoryId == cid) {
        count += entry.counter;
      }
    }
    return count;
  }

  String buildSubtitle(Category category) {
    return "private: ${category.isPrivate}, usage: ${calculateUsage(category.id)}";
  }

  void showOperateMenu(BuildContext context, int index) async {
    final result = await showMenu(
      context: context,
      position: RelativeRect.fromRect(
        _tapPosition & const Size(40, 40),
        Offset.zero & MediaQuery.of(context).size,
      ),
      items: [
        PopupMenuItem(
          value: "edit",
          child: Text(S.of(context).update),
        ),
        PopupMenuItem(
          value: "delete",
          child: Text(S.of(context).delete),
        ),
      ],
      elevation: 8.0,
    );
    if (result == "edit") {
    } else if (result == "delete" && context.mounted) {
      await deleteCategory(context, categories[index]);
      loadData();
    }
  }

  Future<bool> deleteCategory(BuildContext context, category) async {
    ProgressDialog pd = ProgressDialog(context: context);
    pd.show(msg: S.of(context).loading);
    final success = await deleteServerCategory(category.uuid);
    if (success) {
      await _dbHelper.deleteCategory(category.name);
      if (context.mounted) {
        showToast(context, S.of(context).successfully, false);
      }
      pd.close();
      return true;
    } else {
      if (context.mounted) {
        showToast(context, S.of(context).failed, true);
      }
      pd.close();
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).statistics),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTapDown: (details) {
                    _tapPosition = details.globalPosition;
                  },
                  child: Container(
                    color: getColor(_curSelectedIndex, index),
                    child: ListTile(
                      leading: InkWell(
                        child: Text(
                          categories[index].icon,
                          style: const TextStyle(fontSize: 32.0),
                        ),
                      ),
                      title: Text(categories[index].name),
                      subtitle: Text(buildSubtitle(categories[index])),
                      trailing: Text(calculateCount(
                        categories[index].id,
                      ).toString()),
                      onTap: () {
                        setState(() {
                          _curSelectedIndex = index;
                        });
                      },
                      onLongPress: () {
                        showOperateMenu(context, index);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
