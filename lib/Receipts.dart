import 'package:path_provider/path_provider.dart' as path_provider;
import 'dart:io';
import 'dart:convert';

class Receipt {
  final DateTime date;
  final String place;
  final double value;
  
  Receipt(this.date, this.place, this.value);

  Map toJson(){
    return { 'date': date.toIso8601String(), 'place': place, 'value': value };
  }
}

class Receipts {
  final List<Receipt> current = new List<Receipt>();
  final List<Receipt> checked = new List<Receipt>();
  File _store;

  Map toJson(){
    return { 'current': current, 'checked': checked.toList() };
  }

  load() async {
    Directory directory = await path_provider.getApplicationDocumentsDirectory();
    _store = new File('${directory.path}/receipts.json');

    try {
      String s = _store.readAsStringSync();
      dynamic data = json.decode(s);

      for (var r in data['current'])
        current.add(_parse(r));

      for (var r in data['checked'])
        checked.add(_parse(r));
    } on FileSystemException {}
  }

  Receipt _parse(dynamic r){
    DateTime d = DateTime.parse(r['date']);
    String l = r['place'];
    double v = r['value'];

    return new Receipt(d, l, v);
  }
  
  save (){
    _store.writeAsStringSync(json.encode(this));
  }
}