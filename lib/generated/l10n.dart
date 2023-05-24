// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Add Category`
  String get addCategory {
    return Intl.message(
      'Add Category',
      name: 'addCategory',
      desc: '',
      args: [],
    );
  }

  /// `Add Entry`
  String get addEntry {
    return Intl.message(
      'Add Entry',
      name: 'addEntry',
      desc: '',
      args: [],
    );
  }

  /// `Add Parameter`
  String get addParameter {
    return Intl.message(
      'Add Parameter',
      name: 'addParameter',
      desc: '',
      args: [],
    );
  }

  /// `Add Subscription`
  String get addSubscription {
    return Intl.message(
      'Add Subscription',
      name: 'addSubscription',
      desc: '',
      args: [],
    );
  }

  /// `Add successfully`
  String get addSuccessfully {
    return Intl.message(
      'Add successfully',
      name: 'addSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `fclipboard`
  String get appTitle {
    return Intl.message(
      'fclipboard',
      name: 'appTitle',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message(
      'Cancel',
      name: 'cancel',
      desc: '',
      args: [],
    );
  }

  /// `Category`
  String get category {
    return Intl.message(
      'Category',
      name: 'category',
      desc: '',
      args: [],
    );
  }

  /// `Category cannot be empty`
  String get categoryCannotBeEmpty {
    return Intl.message(
      'Category cannot be empty',
      name: 'categoryCannotBeEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Category is not empty`
  String get categoryNotEmpty {
    return Intl.message(
      'Category is not empty',
      name: 'categoryNotEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Clear All`
  String get clearAll {
    return Intl.message(
      'Clear All',
      name: 'clearAll',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure?`
  String get confirmDelete {
    return Intl.message(
      'Are you sure?',
      name: 'confirmDelete',
      desc: '',
      args: [],
    );
  }

  /// `Content`
  String get content {
    return Intl.message(
      'Content',
      name: 'content',
      desc: '',
      args: [],
    );
  }

  /// `Content cannot be empty`
  String get contentCannotBeEmpty {
    return Intl.message(
      'Content cannot be empty',
      name: 'contentCannotBeEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Delete`
  String get delete {
    return Intl.message(
      'Delete',
      name: 'delete',
      desc: '',
      args: [],
    );
  }

  /// `All entries deleted successfully`
  String get deleteAllSuccess {
    return Intl.message(
      'All entries deleted successfully',
      name: 'deleteAllSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Delete successfully`
  String get deleteSuccess {
    return Intl.message(
      'Delete successfully',
      name: 'deleteSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Description`
  String get description {
    return Intl.message(
      'Description',
      name: 'description',
      desc: '',
      args: [],
    );
  }

  /// `Export`
  String get export {
    return Intl.message(
      'Export',
      name: 'export',
      desc: '',
      args: [],
    );
  }

  /// `Import`
  String get import {
    return Intl.message(
      'Import',
      name: 'import',
      desc: '',
      args: [],
    );
  }

  /// `Initial`
  String get initial {
    return Intl.message(
      'Initial',
      name: 'initial',
      desc: '',
      args: [],
    );
  }

  /// `Listing`
  String get listing {
    return Intl.message(
      'Listing',
      name: 'listing',
      desc: '',
      args: [],
    );
  }

  /// `Loading`
  String get loading {
    return Intl.message(
      'Loading',
      name: 'loading',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get name {
    return Intl.message(
      'Name',
      name: 'name',
      desc: '',
      args: [],
    );
  }

  /// `No parameters`
  String get noParameters {
    return Intl.message(
      'No parameters',
      name: 'noParameters',
      desc: '',
      args: [],
    );
  }

  /// `OK`
  String get ok {
    return Intl.message(
      'OK',
      name: 'ok',
      desc: '',
      args: [],
    );
  }

  /// `Required`
  String get required {
    return Intl.message(
      'Required',
      name: 'required',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get save {
    return Intl.message(
      'Save',
      name: 'save',
      desc: '',
      args: [],
    );
  }

  /// `Search`
  String get searchHint {
    return Intl.message(
      'Search',
      name: 'searchHint',
      desc: '',
      args: [],
    );
  }

  /// `Subscribe`
  String get subscribe {
    return Intl.message(
      'Subscribe',
      name: 'subscribe',
      desc: '',
      args: [],
    );
  }

  /// `Subscribe failed`
  String get subscribeFailed {
    return Intl.message(
      'Subscribe failed',
      name: 'subscribeFailed',
      desc: '',
      args: [],
    );
  }

  /// `Subscribe successfully`
  String get subscribeSuccessfully {
    return Intl.message(
      'Subscribe successfully',
      name: 'subscribeSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `Title`
  String get title {
    return Intl.message(
      'Title',
      name: 'title',
      desc: '',
      args: [],
    );
  }

  /// `Title cannot be empty`
  String get titleCannotBeEmpty {
    return Intl.message(
      'Title cannot be empty',
      name: 'titleCannotBeEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Update`
  String get update {
    return Intl.message(
      'Update',
      name: 'update',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'zh'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
