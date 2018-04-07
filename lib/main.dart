import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:collection';
import 'package:location/location.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

void main() => runApp(new ReceiptsApp());
///
class ReceiptsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Receipts',
      home: new Receipts(),
    );
  }
}

class Receipts extends StatefulWidget {
  @override
  createState() => new ReceiptsState();
}

class Reciept {
  DateTime date;
  String location;
  double value;
  Reciept(DateTime d, String l, double v) {
    date = d;
    location = l;
    value = v;
  }
}
class ReceiptsState extends State<Receipts> {
  final List<String> _places = <String>[];
  final Queue<Reciept> _receipts = new Queue<Reciept>();
  final Queue<Reciept> _doneReceipts = new Queue<Reciept>();
  final TextStyle _biggerFont = const TextStyle(color: Colors.black, fontSize: 16.0, fontWeight: FontWeight.bold);
  TextField _valueTextField;
  final TextEditingController _valueCtrl = new TextEditingController();

  @override
  void initState() {
    super.initState();
    getPlaces();
  }

  getPlaces() async {
    Location _location = new Location();
    Map<String,double> location;
    dynamic data;

    try {
      location = await _location.getLocation;
    } catch (e){
      location = null;
    }

    try {
      var uri = new Uri.https(
      /*    'maps.googleapis.com', '/maps/api/place/nearbysearch/json', {
        'key': 'AIzaSyCErmNo5wVAFa68O49BoihbeQz_Jtyk8Zk',
        'location': "-37.934747,145.038774",
        'radius': '20'
      });*/
      'maps.googleapis.com', '/maps/api/place/nearbysearch/json', {'key': 'AIzaSyCErmNo5wVAFa68O49BoihbeQz_Jtyk8Zk', 'location': "${location["latitude"]},${location["longitude"]}", 'radius': '20'});

      var response = await http.get(uri);
      data = JSON.decode(response.body);
    } catch (e) {
      data = e.toString();
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      for (var r in data['results']) _places.add(r['name']);
//      _places.add('test');
    });
  }

  @override
  Widget build(BuildContext context) {

    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Add Receipt'),
        actions: <Widget>[
          new IconButton(icon: new Icon(Icons.list), onPressed: _pushReceipts),
        ],
      ),
      body: _buildInput(),
    );
  }

  Widget _buildInput() {
    _valueTextField = new TextField(controller: _valueCtrl, autofocus: true, keyboardType: TextInputType.number, textAlign: TextAlign.center, style: _biggerFont,);

    return new Column(
        children: <Widget>[
          _valueTextField,
          new Expanded(child: new ListView.builder(
            itemBuilder: (context, i)
            {
              if(i >= _places.length)
                return null;
              else
                return _buildRow(_places[i]);
            },
          )),
        ]
    );
  }

  Widget _buildRow(String place) {
    return new ListTile(
      title: new Text(
        place,
        style: _biggerFont,
      ),
      onTap: () {
        setState(() {
          _receipts.add(new Reciept(new DateTime.now(), place, double.parse(_valueCtrl.text)));
        });
      },
    );
  }

  void _pushReceipts() {
    Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (context) {
          final tiles = _receipts.map(
            (Reciept receipt) {
              var formatter = new DateFormat('yyyy-MM-dd hh:mm');
              String formatted = formatter.format(receipt.date.toLocal());
              return new ListTile(
                title: new Text(
                  '${formatted} ${receipt.location} ${receipt.value}',
                  style: _biggerFont,
                ),
                onTap: () {
                  _receipts.remove(receipt);
                  setState(() {});
                  },
              );
            },
          );
          final divided = ListTile
              .divideTiles(
                context: context,
                tiles: tiles,
              )
              .toList();
          return new Scaffold(
            appBar: new AppBar(
              title: new Text('Receipts'),
              actions: <Widget>[
                new IconButton(icon: new Icon(Icons.undo), onPressed: _undo),
              ],

            ),
            body: new ListView(children: divided),
          );
        },
      ),
    );
  }

  void _undo(){}
}
