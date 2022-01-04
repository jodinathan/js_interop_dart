import 'dart:async';
import 'dart:js' as js;
import 'dart:html' as html;
import 'dart:js_util' as jsu;
import 'package:js/js.dart';

typedef InteropedMap = js.JsObject;

class JsInterop {
  static final Map<String, Future<bool>> _scriptFetched = {};

  static F fn<F extends Function>(F original) => allowInterop(original);

  static InteropedMap map(Map<String, dynamic> map) {
    final object = jsu.newObject<InteropedMap>();
    final len = map.length;
    final keys = map.keys;
    final values = map.values;

    for (var x = 0; x < len; x++) {
      jsu.setProperty(object, keys.elementAt(x), values.elementAt(x));
    }

    return object;
  }

  static html.ScriptElement script(String buffer) => html.ScriptElement()
    ..async = true
    ..type = 'text/javascript'
    ..appendText(buffer);

  static bool hasContext(String contextCheck) {
    final ret = js.context.hasProperty(contextCheck) &&
        js.context[contextCheck] != null &&
        js.context[contextCheck].toString() != 'null';

    print('HasContext $contextCheck, $ret');

    return ret;
  }

  static Future<bool> safeAddScript(String name, String buffer,
      {String? contextCheck}) async {
    contextCheck ??= name;
    assert(buffer.isNotEmpty == true);

    if (hasContext(contextCheck)) return true;

    if (!_scriptFetched.containsKey(name)) {
      final c = Completer<bool>();

      print('AddingScript $name');
      _scriptFetched[name] = c.future;
      html.document.body!.children.add(script(buffer));

      Timer.periodic(Duration(milliseconds: 300), (t) {
        if (hasContext(contextCheck!)) {
          t.cancel();
          c.complete(true);
        }
      });
    }

    return _scriptFetched[name]!;
  }
}
