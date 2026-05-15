

abstract class DataDiskEncoder {

     // integer
    void setInt({required int? value, required String key });
    int? integerFor({ required String key });
    // string
    void setString({ required String? value, required String key });
    String? stringFor({ required String key});
    // boolean
    void setBoolean({ required bool? value, required String key });
    bool? boolFor({ required String key });
    // double
    void setDouble({ required double? value, required String key });
    double? doubleFor({ required String key });
    // specific key
    void eraseKey({ required String key });
    // all keys
    void eraseAllKeys();
}
