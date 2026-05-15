

import 'package:http/http.dart';

extension ResponseSuccess on Response {
  bool get isSuccess => this.statusCode >= 200 && this.statusCode <= 299;
}