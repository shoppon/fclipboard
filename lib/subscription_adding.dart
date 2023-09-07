import 'dart:convert';
import 'dart:developer';

import 'package:fclipboard/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:json_schema/json_schema.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';

import 'dao.dart';
import 'generated/l10n.dart';

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
    final schema = JsonSchema.create(json.decode(content));
    final result = schema.validate(decodedResponse);
    if (!result.isValid) {
      throw Exception('Invalid schema');
    }

    await DBHelper().importFromYaml(decodedResponse);
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

class SubscriptionAddingPage extends StatefulWidget {
  const SubscriptionAddingPage({Key? key}) : super(key: key);

  @override
  State<SubscriptionAddingPage> createState() => _SubscriptionAddingPageState();
}

class _SubscriptionAddingPageState extends State<SubscriptionAddingPage> {
  String url = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).subscribe),
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
                ProgressDialog pd = ProgressDialog(context: context);
                pd.show(msg: S.of(context).loading);
                final subscriber = Subscriber(url: url);
                final success = await subscriber.trySubscribe();
                if (success) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    showToast(
                        context, S.of(context).subscribeSuccessfully, false);
                  }
                } else {
                  if (context.mounted) {
                    showToast(context, S.of(context).subscribeFailed, true);
                  }
                }
                pd.close();
              },
              child: Text(S.of(context).subscribe),
            )
          ],
        ),
      ),
    );
  }
}
