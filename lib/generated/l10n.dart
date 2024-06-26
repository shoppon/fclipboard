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

  /// `Add Failed`
  String get addFailed {
    return Intl.message(
      'Add Failed',
      name: 'addFailed',
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

  /// `Your Second Brain`
  String get appTitle {
    return Intl.message(
      'Your Second Brain',
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

  /// `Be careful!`
  String get clearWarning {
    return Intl.message(
      'Be careful!',
      name: 'clearWarning',
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

  /// `Creating Subscription`
  String get creatingSubscription {
    return Intl.message(
      'Creating Subscription',
      name: 'creatingSubscription',
      desc: '',
      args: [],
    );
  }

  /// `Debug Mode`
  String get debugMode {
    return Intl.message(
      'Debug Mode',
      name: 'debugMode',
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

  /// `Delete failed`
  String get deleteFailed {
    return Intl.message(
      'Delete failed',
      name: 'deleteFailed',
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

  /// `Edit Server Address`
  String get editServerAddr {
    return Intl.message(
      'Edit Server Address',
      name: 'editServerAddr',
      desc: '',
      args: [],
    );
  }

  /// `Error format`
  String get errorFormat {
    return Intl.message(
      'Error format',
      name: 'errorFormat',
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

  /// `Export successfully`
  String get exportSuccessfully {
    return Intl.message(
      'Export successfully',
      name: 'exportSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `Failed`
  String get failed {
    return Intl.message(
      'Failed',
      name: 'failed',
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

  /// `Import failed`
  String get importFailed {
    return Intl.message(
      'Import failed',
      name: 'importFailed',
      desc: '',
      args: [],
    );
  }

  /// `Import successfully`
  String get importSuccessfully {
    return Intl.message(
      'Import successfully',
      name: 'importSuccessfully',
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

  /// `invalid format`
  String get invalidFormat {
    return Intl.message(
      'invalid format',
      name: 'invalidFormat',
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

  /// `Loading failed`
  String get loadFailed {
    return Intl.message(
      'Loading failed',
      name: 'loadFailed',
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

  /// `Login`
  String get login {
    return Intl.message(
      'Login',
      name: 'login',
      desc: '',
      args: [],
    );
  }

  /// `Please retry after login`
  String get loginTooltip {
    return Intl.message(
      'Please retry after login',
      name: 'loginTooltip',
      desc: '',
      args: [],
    );
  }

  /// `Annotations`
  String get modeAnnotation {
    return Intl.message(
      'Annotations',
      name: 'modeAnnotation',
      desc: '',
      args: [],
    );
  }

  /// `Notes`
  String get modeNotes {
    return Intl.message(
      'Notes',
      name: 'modeNotes',
      desc: '',
      args: [],
    );
  }

  /// `Select Mode`
  String get modeSwitch {
    return Intl.message(
      'Select Mode',
      name: 'modeSwitch',
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

  /// `Paste`
  String get paste {
    return Intl.message(
      'Paste',
      name: 'paste',
      desc: '',
      args: [],
    );
  }

  /// `Paste successfully`
  String get pasteSuccessfully {
    return Intl.message(
      'Paste successfully',
      name: 'pasteSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `Please input phone number`
  String get phoneInput {
    return Intl.message(
      'Please input phone number',
      name: 'phoneInput',
      desc: '',
      args: [],
    );
  }

  /// `Profile`
  String get profile {
    return Intl.message(
      'Profile',
      name: 'profile',
      desc: '',
      args: [],
    );
  }

  /// `Pushing...`
  String get pushing {
    return Intl.message(
      'Pushing...',
      name: 'pushing',
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

  /// `Server Address`
  String get serverAddr {
    return Intl.message(
      'Server Address',
      name: 'serverAddr',
      desc: '',
      args: [],
    );
  }

  /// `Setting successfully`
  String get settingSuccess {
    return Intl.message(
      'Setting successfully',
      name: 'settingSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Share`
  String get share {
    return Intl.message(
      'Share',
      name: 'share',
      desc: '',
      args: [],
    );
  }

  /// `Statistics`
  String get statistics {
    return Intl.message(
      'Statistics',
      name: 'statistics',
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

  /// `Subscription List`
  String get subscriptionList {
    return Intl.message(
      'Subscription List',
      name: 'subscriptionList',
      desc: '',
      args: [],
    );
  }

  /// `Successfully`
  String get successfully {
    return Intl.message(
      'Successfully',
      name: 'successfully',
      desc: '',
      args: [],
    );
  }

  /// `Sync Apple Books`
  String get syncAppleBooks {
    return Intl.message(
      'Sync Apple Books',
      name: 'syncAppleBooks',
      desc: '',
      args: [],
    );
  }

  /// `Sync Cloud`
  String get syncCloud {
    return Intl.message(
      'Sync Cloud',
      name: 'syncCloud',
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

  /// `Version`
  String get version {
    return Intl.message(
      'Version',
      name: 'version',
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
