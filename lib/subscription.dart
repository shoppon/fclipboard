import 'dart:convert';
import 'dart:developer';

import 'package:fclipboard/flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fclipboard/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:json_schema2/json_schema2.dart';

import 'dao.dart';
import 'model.dart';

class Subscriber {
  String url;

  Subscriber({
    required this.url,
  });

  Future<void> subscribe() async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to subscribe to $url');
    }

    final decodedResponse = json.decode(utf8.decode(response.bodyBytes));
    final content =
        await rootBundle.loadString('assets/schemas/subscription.json');
    final schema = JsonSchema.createSchema(json.decode(content));
    final isValid = schema.validate(decodedResponse);
    if (!isValid) {
      throw Exception('Invalid schema');
    }

    final dbHelper = DBHelper();
    for (var c in decodedResponse['categories']) {
      await dbHelper.insertCategory(Category(
        name: c['name'],
        icon: c['icon'],
      ));
    }
    final categories = await dbHelper.categories();
    for (var e in decodedResponse['entries']) {
      final c = categories.firstWhere((c) => c.name == e['category']);
      await dbHelper.insertEntry(Entry(
        title: "${c.name}_${e['title']}",
        subtitle: e['subtitle'],
        counter: 0,
        categoryId: c.id,
      ));
    }
  }

  Future<bool> trySubscribe() async {
    try {
      await subscribe();
      return true;
    } catch (e) {
      log('Failed to subscribe to $url');
      return false;
    }
  }
}

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({Key? key}) : super(key: key);

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  String url = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).subscribe),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'URL',
              ),
              onChanged: (value) {
                url = value;
              },
              validator: (value) {
                final url = Uri.tryParse(value!);
                if (url == null) {
                  return 'Invalid URL';
                }
                return value;
              },
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                final subscriber = Subscriber(url: url);
                final success = await subscriber.trySubscribe();
                if (success) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    showToast(
                        context,
                        AppLocalizations.of(context).subscribeSuccessfully,
                        false);
                  }
                } else {
                  if (context.mounted) {
                    showToast(context,
                        AppLocalizations.of(context).subscribeFailed, true);
                  }
                }
              },
              child: Text(AppLocalizations.of(context).subscribe),
            )
          ],
        ),
      ),
    );
  }
}
