import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:location/location.dart';
import 'package:flutter/services.dart';
import 'Receipts.dart';
import 'ReceiptsListView.dart';

final TextStyle _biggerFont = const TextStyle(
    color: Colors.black, fontSize: 16.0, fontWeight: FontWeight.bold);
final TextStyle _biggestFont = const TextStyle(
    color: Colors.black, fontSize: 24.0, fontWeight: FontWeight.bold);

void main() => runApp(new ReceiptsApp());

class ReceiptsApp extends StatelessWidget {
  static final Receipts receipts = new Receipts();

  @override
  Widget build(BuildContext context) {

    return new MaterialApp(
      title: 'Receipts',
      home: new NewReceiptWidget(),
    );
  }
}

class NewReceiptWidget extends StatefulWidget {
  @override
  createState() => new NewReceiptState();
}

class NewReceiptState extends State<NewReceiptWidget> with WidgetsBindingObserver {

  Receipts _receipts;
  StreamSubscription<Map<String, double>> _locationSubscription;

  final Set<String> _places = new Set<String>();
  final TextEditingController _valueCtrl = new TextEditingController();
  final Location _location = new Location();

  NewReceiptState(){
    _receipts = ReceiptsApp.receipts;
    _receipts.load();
  }

  @override
  void initState() {
    super.initState();
    _locationSubscription = _location.onLocationChanged.listen(getPlaces);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch(state)
    {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.suspending:
        _receipts.save();
        _locationSubscription.cancel();
        break;
      case AppLifecycleState.resumed:
        _locationSubscription = _location.onLocationChanged.listen(getPlaces);
        break;
    }
    if(state == AppLifecycleState.paused){
    }
  }

  getPlaces(Map<String, double> location) async {
    try {
      dynamic data;

      var uri = new Uri.https(
          'maps.googleapis.com', '/maps/api/place/nearbysearch/json', {
        'key': 'AIzaSyCErmNo5wVAFa68O49BoihbeQz_Jtyk8Zk',
        'location': "${location["latitude"]},${location["longitude"]}",
        'radius': '${location["accuracy"]}'
      });

        http.Response response = await http.get(uri);
        data = json.decode(response.body);

      // If the widget was removed from the tree while the asynchronous platform
      // message was in flight, we want to discard the reply rather than calling
      // setState to update our non-existent appearance.
      if (!mounted) return;

      if (data != null)
        setState(() {
          try {
            for (var r in data['results'])
              _places.add(r['name']);
          } catch (e) {
            print(e);
          }
        });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text('Add Receipt'), actions: <Widget>[
        new IconButton(
          icon: new Icon(Icons.list),
          onPressed: () {
            Navigator.push(context, new MaterialPageRoute(builder: (context) {
              return new CurrentReceiptsWidget();
            }));
          },
        )
      ]),
      body: _buildAddReceipt(),
    );
  }

  Widget _buildAddReceipt() {
    return new Column(children: <Widget>[
        new Row(children: <Widget>[
        new Expanded(child: new TextField(
          controller: _valueCtrl,
          inputFormatters: <TextInputFormatter>[ new WhitelistingTextInputFormatter(new RegExp(r'^\d+.?\d?\d?'))],
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.left,
          style: _biggestFont,
          decoration: new InputDecoration(
              prefixIcon: new Icon(Icons.attach_money, color: Colors.black, size: 32.0)),
        )),
        new FlatButton(child: new Text('Add'),onPressed: (){ _addReceipt('');})]),
      new Expanded(child: new ListView.builder(
        itemBuilder: (context, i) {
          if (i >= _places.length)
            return null;
          else
            return _buildPlaceRow(_places.elementAt(i));
        },
      )),
    ]);
  }

  Widget _buildPlaceRow(String place) {
    return new ListTile(
      title: new Text(
        place,
        style: _biggerFont,
      ),
      onTap: () {
        _addReceipt(place);
      },
    );
  }

  void _addReceipt(String place) {
    setState(() {
      double value;

      try {
        value = double.parse(_valueCtrl.text);
      } catch (e) {}

      if (value != null) {
        _receipts.current.insert(0, new Receipt(
            new DateTime.now(), place, value));

        SystemNavigator.pop();
      }
    });
  }
}

class CurrentReceiptsWidget extends StatefulWidget {
  @override
  createState() => new CurrentReceiptsState();
}

class CurrentReceiptsState extends State<CurrentReceiptsWidget> {
  Receipts _receipts;

  CurrentReceiptsState()
  {
    _receipts = ReceiptsApp.receipts;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Receipts'),
        actions: <Widget>[
          new IconButton(icon: new Icon(Icons.undo), onPressed: _undo),
          new IconButton(icon: new Icon(Icons.list), onPressed: () {
            Navigator.push(context, new MaterialPageRoute(builder: (context) {
              return new CheckedReceiptsWidget();
            }));}),
        ],
      ),
      body: new ReceiptsListView(_receipts.current, Icons.delete, Icons.delete, (direction, receipt){
        _delete(direction, receipt);
        }),
    );
  }

  void _undo() {
    setState((){
      if(_receipts.checked.length > 0)
        _receipts.current.insert(0, _receipts.checked.removeAt(0));
    });
  }

  void _delete(direction, receipt) {
    setState(() {
      _receipts.current.remove(receipt);
      _receipts.checked.insert(0, receipt);
    });
  }
}

class CheckedReceiptsWidget extends StatefulWidget {
  @override
  createState() => new CheckedReceiptsState();
}

class CheckedReceiptsState extends State<CheckedReceiptsWidget> {
  Receipts _receipts;

  CheckedReceiptsState()
  {
    _receipts = ReceiptsApp.receipts;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Checked Receipts'),
        actions: <Widget>[
          new IconButton(icon: new Icon(Icons.delete_forever), onPressed: _delete),
        ],
      ),
      body: new ReceiptsListView(_receipts.checked, Icons.undo, Icons.delete, _restore),
    );
  }

  void _restore(direction, receipt) {
    setState((){
      _receipts.checked.remove(receipt);

      if(direction == DismissDirection.endToStart)
      _receipts.current.insert(0, receipt);
    });
  }

  Future<Null> _delete() {
    return showDialog<Null>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text('Permanently delete all checked receipts?'),
            actions: <Widget>[
              new FlatButton(
                child: new Text('No'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              new FlatButton(
                child: new Text('Yes'),
                onPressed: () {
                  setState(() {
                    _receipts.checked.clear();
                  });
                  Navigator.pop(context);
                },
              ),
          ],
        );
      },
    );
  }
}
