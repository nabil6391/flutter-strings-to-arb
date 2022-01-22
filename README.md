# flutter-strings-to-arb

Flutter’s internationalisation is a solid approach to support localisation in the apps. However there is no easy way to extract strings from the dart codes into the arbs. The Flutter Intl plugin supports exporting strings using the IDE’s context menu but that is only available for single strings. So I created a code we can run to extract almost all strings from the codes.

Technical Details

What it does is that it searches for double and single qouted strings in a line and fetches the word/sentence in between.

## Extract Strings to arb
- Open strings_to_arb.dart
- Make sure write = true at line 67.
- In Android studio , run strings_to_arb by right clicking -> run
- This will show the list of strings that are still present in the Dart files, keep in mind some strings do not need to be copied. It will copy all the strings to the outputFilename mentioned in the file, by default it is intl_en.arb.dart.

## Find all strings present in the codes
- Open strings_to_arb.dart
- Make sure write = false at line 67.
- In Android studio , run strings_to_arb by right clicking -> run
- This will show the list of strings that are still present in the Dart files, keep in mind some strings do not need to be copied.
Install Flutter Intl plugin in Android Studio. After installing that plugin, it should show an extract to arb view action whenever we are over a string. (the left bulb icon) . Use that to extract all remaining strings.

## Skip Folders and Files that you want to manually extract
- Modify the variable skipFiles at line 71
- To skip folders: add the names of the folders in the strings_to_arb.dart
- To skip files: add the name of the file along with its extension.
- var skipFiles = ["strings_to_arb.dart", "models", "generated"];
- The above code with skip the strings_to_arb.dart file and ‘models’ and ‘generated’ folders.
