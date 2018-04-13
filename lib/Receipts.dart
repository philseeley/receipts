import 'package:path_provider/path_provider.dart' as path_provider;
import 'dart:io';
import 'dart:convert';

class Reciept {
  final DateTime date;
  final String place;
  final double value;
  
  Reciept(this.date, this.place, this.value);

  Map toJson(){
     return { 'date': date.toIso8601String(), 'place': place, 'value': value };
  }
}

class Receipts {
  final List<Reciept> current = new List<Reciept>();
  final List<Reciept> checked = new List<Reciept>();
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

  Reciept _parse(dynamic r){
    DateTime d = DateTime.parse(r['date']);
    String l = r['place'];
    double v = r['value'];

    return new Reciept(d, l, v);
  }
  
  save (){
    _store.writeAsStringSync(json.encode(this));
  }
}