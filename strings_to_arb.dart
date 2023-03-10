import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

const String sourceKey = 'source';
const String sourceDefault = './lib/';

const String outputKey = 'output';
const String outputDefault = './lib/l10n/';

const String createPathsKey = 'create-paths';
const bool createPathsKeyDefault = true;

Future<void> main(List<String> arguments) async {
  final ArgParser parser = ArgParser()
    ..addOption(
      sourceKey,
      abbr: 's',
      help: 'Specify where to search for the arb files.',
      valueHelp: sourceDefault,
      defaultsTo: sourceDefault,
    )
    ..addOption(
      outputKey,
      abbr: 'o',
      help: 'Specify where to save the generated dart files.',
      valueHelp: outputDefault,
      defaultsTo: outputDefault,
    )
    ..addFlag(
      'create-paths',
      abbr: 'c',
      help: 'This will create the folders structure recursevly.',
      defaultsTo: createPathsKeyDefault,
    );

  if (arguments.isNotEmpty && arguments[0] == 'help') {
    stdout.writeln(parser.usage);
    return;
  }

  final ArgResults result = parser.parse(arguments);

  final String source = path.canonicalize(path.absolute(result[sourceKey]));
  final String output = path.canonicalize(path.absolute(result[outputKey]));
  final bool createPaths = result[createPathsKey];

  final Directory sourceDir = Directory(source);
  final Directory outputDir = Directory(output);
  print('sada');
  print(sourceDir);
  print(outputDir);

  if (createPaths) {
    if (!sourceDir.existsSync()) {
      sourceDir.createSync(recursive: true);
    }

    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }
  }

  var write = false;

  Map<String, String> allMessages = {};

  var skipFiles = ["strings_to_arb.dart", "models", "provider", "generated"];
  recursiveFolderCopySync(source, skipFiles, allMessages, write);

  var locale = "en";

  if (locale != null) {
    allMessages["@@locale"] = locale;
  }

  allMessages["@@last_modified"] = new DateTime.now().toIso8601String();

  String outputFilename = "intl_en.arb";
  var outputFile = new File(path.join(outputDir.path, outputFilename));
  var encoder = new JsonEncoder.withIndent("  ");

  // List<String> sortedKeys = allMessages.keys.toList(growable: false)..sort((k1, k2) => k1.compareTo(k2));
  // allMessages = Map.fromIterable(sortedKeys);
  print(allMessages);

  if(write) {
    outputFile.writeAsStringSync(encoder.convert(allMessages));
  }
}

void recursiveFolderCopySync(String source, List<String> skips, Map<dynamic, dynamic> allMessages, bool write) {
  Directory directory = new Directory(source);
  var skipWords = ["dart:ui", "dart:io"];
  var finder = DartHardCodedStringFinder(skipWords);
  directory.listSync().forEach((element) {
    print(element);
    var shouldSkip = skips.contains(path.basename(element.path));
    if (element is File) {
      if (path.extension(element.path) == ".dart" && !shouldSkip) {
        var content = element.readAsStringSync();
        var stringsFounded = finder.findHardCodedStrings(content);
        if (stringsFounded.isNotEmpty) {
          print(stringsFounded);

          if (content.contains("context")) {
            //only change strings if there is a context for replacing
            content = "import 'package:islamic_quiz_flutter/generated/l10n.dart';\n" + content;
            stringsFounded.forEach((element) {
              // if (skipWords.any((word) => element.contains(word))) {
                allMessages[finder.getCamelCase(element)] = element;
                content = content.replaceAll("\"$element\"", "S.of(context).${finder.getCamelCase(element)}");
                content = content.replaceAll("\'$element\'", "S.of(context).${finder.getCamelCase(element)}");
              // }
            });
            // element.writeAsString(content);
          }
        }
      }
    } else if (element is Directory && !shouldSkip) {
      recursiveFolderCopySync(element.path, skips, allMessages, write);
    }
  });
}


class DartHardCodedStringFinder {
  List<String> skipWords;

  DartHardCodedStringFinder(this.skipWords);

  bool shouldInclude(String it) {
    return it.isNotEmpty &&
        !it.contains("assets") &&
        !it.contains(".png") &&
        !it.contains(".jpeg") &&
        !it.contains(".mp3") &&
        !it.contains(".mkv") &&
        !it.contains("_") && //most probably api stuff
        !it.contains("/") && //path
        !it.contains("#") && // color stuff
        it.trim().length > 1 && //most probably not needed
        !it.contains(".svg");
  }

  var regex = RegExp("\".*?\"");
  var regexDart = RegExp("\'.*?\'");

  String extractHardCodedString(String it, String input) {
    return it.replaceAll("\"", "").replaceAll("\'", "").trim();
  }

  /// Returns a string in the form "UpperCamelCase" or "lowerCamelCase".
  ///
  /// Example:
  ///      print(camelize("dart_vm"));
  ///      => DartVm
  String getCamelCase(String _words, {String separator: ''}) {
    List<String> words = _words
        .replaceAll("\"", "")
        .replaceAll(".", "")
        .replaceAll(",", "")
        .replaceAll("?", "")
        .replaceAll("&", "")
        .replaceAll("%", "")
        .replaceAll("*", "")
        .replaceAll("(", "")
        .replaceAll(")", "")
        .replaceAll("!", "")
        .replaceAll("-", "")
        .replaceAll("/", "")
        .replaceAll("|", "")
        .split(" ")
        .map((e) => _upperCaseFirstLetter(e))
        .toList();

    if (_words.isNotEmpty) {
      words[0] = words[0].toLowerCase();
    }

    return words.join(separator);
  }

  String _upperCaseFirstLetter(String word) {
    return word.length > 1 ? '${word.substring(0, 1).toUpperCase()}${word.substring(1).toLowerCase()}' : word;
  }

  List<String> findHardCodedStrings(String content) {
    Iterable<RegExpMatch> result = regex.allMatches(content);

    var strings = <String>[];

    result
        .where((e) => e.group(0) != null)
        .forEach((e) {
      var string = extractHardCodedString(e.group(0)!, e.input);

      var jsonParamAccessString = e.input.codeUnitAt(e.start-1) =='['.codeUnits.first && e.input.codeUnitAt(e.end) ==']'.codeUnits.first;
      var jsonParamSetString =  e.input.codeUnitAt(e.end) ==':'.codeUnits.first;
      var uselessArguements =  string.startsWith("\$\{") && string.endsWith("}") ;

      var include = shouldInclude(string) && !jsonParamSetString && !jsonParamAccessString && !uselessArguements;
      if (include) {
        strings.add(string);
      }
    });

    Iterable<RegExpMatch> result1 = regexDart.allMatches(content);

    result1
        .where((e) => e.group(0) != null)
        .forEach((e) {
      var string = extractHardCodedString(e.group(0)!, e.input);

      var jsonParamAccessString = e.input.codeUnitAt(e.start-1) =='['.codeUnits.first && e.input.codeUnitAt(e.end) ==']'.codeUnits.first;
      var jsonParamSetString =  e.input.codeUnitAt(e.end) ==':'.codeUnits.first;
      var uselessArguements =  string.startsWith("\$\{") && string.endsWith("}") ;

      var include = shouldInclude(string) && !jsonParamSetString && !jsonParamAccessString && !uselessArguements;
      if (include) {
        strings.add(string);
      }
    });

    return strings;
  }
}
