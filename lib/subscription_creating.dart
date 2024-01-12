import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:openapi/api.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';

import 'dao.dart';
import 'model.dart' as m;
import 'utils.dart';
import 'generated/l10n.dart';

var logger = Logger();

class SubscriptionCreatingPage extends StatefulWidget {
  const SubscriptionCreatingPage({super.key});

  @override
  State<SubscriptionCreatingPage> createState() => _SubscriptionCreatingState();
}

class _SubscriptionCreatingState extends State<SubscriptionCreatingPage> {
  final _formKey = GlobalKey<FormState>();
  final _dbHelper = DBHelper();

  List<bool> _selected = [];
  List<m.Category> _categories = [];

  String _name = "";

  @override
  void initState() {
    super.initState();

    _loadCategories().then((categories) {
      setState(() {
        _selected = List<bool>.filled(categories.length, false);
        _categories = categories;
      });
    });
  }

  Future<List<m.Category>> _loadCategories() async {
    final categories = await _dbHelper.categories();
    return categories;
  }

  Future<void> _createCategory(List<String> categories, String name) async {
    ProgressDialog pd = ProgressDialog(context: context);
    pd.show(msg: "Loading...");
    final email = loadUserEmail();
    final apiInstance =
        SubscriptionApi(ApiClient(basePath: await loadServerAddr()));
    final req = SubscriptionPostReq(
      subscription: SubscriptionPostReqSubscription(
        categories: categories,
        name: name,
        // TODO(xp): add public input
        public: false,
      ),
    );
    try {
      await apiInstance.createSubscription(email, subscriptionPostReq: req);
      if (context.mounted) {
        showToast(context, S.of(context).addSuccessfully, false);
      }
    } catch (e) {
      logger.e("Failed to create subscription", error: e);
      if (context.mounted) {
        showToast(context, S.of(context).addFailed, true);
      }
    } finally {
      pd.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).addSubscription),
      ),
      body: FutureBuilder(
        future: _loadCategories(),
        builder:
            (BuildContext context, AsyncSnapshot<List<m.Category>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            List<m.Category> cats = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(18.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: S.of(context).name,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return S.of(context).titleCannotBeEmpty;
                        }
                        _name = value;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    Expanded(
                      flex: 1,
                      child: ListView.builder(
                        itemCount: cats.length,
                        itemBuilder: (BuildContext context, index) {
                          return CheckboxListTile(
                            title: Text(cats[index].icon + cats[index].name),
                            value: _selected[index],
                            onChanged: (bool? value) {
                              setState(() {
                                _selected[index] = value!;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) {
                          return;
                        }
                        final items = _categories
                            .whereIndexed((index, element) => _selected[index])
                            .toList();
                        final names = items.map((e) => e.name).toList();
                        _createCategory(names, _name);
                        Navigator.pop(context);
                      },
                      child: Text(S.of(context).addCategory),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
