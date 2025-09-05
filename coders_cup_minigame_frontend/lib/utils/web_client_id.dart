// Web-only implementation
import 'dart:html' as html;

String? getWebClientId() {
  final meta = html.document.querySelector('meta[name="google-signin-client_id"]') as html.MetaElement?;
  return meta?.content;
}
