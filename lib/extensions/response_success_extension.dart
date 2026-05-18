

import 'package:http/http.dart';

extension ResponseSuccess on Response {
  bool get isSuccess => statusCode >= 200 && statusCode <= 299;
}