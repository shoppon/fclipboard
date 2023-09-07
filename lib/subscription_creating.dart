import 'package:collection/collection.dart';
import 'package:fclipboard/model.dart';
import 'package:flutter/material.dart';
import 'package:openapi/api.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dao.dart';
import 'utils.dart';
import 'generated/l10n.dart';

class SubscriptionCreatingPage extends StatefulWidget {
  const SubscriptionCreatingPage({super.key});

  @override
  State<SubscriptionCreatingPage> createState() => _SubscriptionCreatingState();
}

class _SubscriptionCreatingState extends State<SubscriptionCreatingPage> {
  final _formKey = GlobalKey<FormState>();
  final _dbHelper = DBHelper();

  List<bool> _selected = [];
  List<Category> _categories = [];

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

  Future<List<Category>> _loadCategories() async {
    final categories = await _dbHelper.categories();
    return categories;
  }

  Future<String> _loadUserEmail() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("fclipboard.email")!;
  }

  Future<void> _createCategory(List<String> categories, String name) async {
    ProgressDialog pd = ProgressDialog(context: context);
    pd.show(msg: "Loading...");
    final email = await _loadUserEmail();
    final apiInstance =
        DefaultApi(ApiClient(basePath: 'http://localhost:8000'));
    final req = SubscriptionPostReq(
      subscription: SubscriptionPostReqSubscription(
        categories: categories,
        name: name,
      ),
    );
    try {
      await apiInstance.createSubscription(email, subscriptionPostReq: req);
      if (context.mounted) {
        showToast(context, S.of(context).addSuccessfully, false);
      }
    } catch (e) {
      if (context.mounted) {
        showToast(context, S.of(context).addFailed, false);
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
            (BuildContext context, AsyncSnapshot<List<Category>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            List<Category> cats = snapshot.data!;
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
