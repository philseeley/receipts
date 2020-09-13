import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import 'package:location/location.dart';
import 'package:flutter/services.dart';
import 'package:share/share.dart';
import 'package:intl/intl.dart';

import 'Receipts.dart';
import 'ReceiptsListView.dart';

void main() => runApp(new ReceiptsApp());

class ReceiptsApp extends StatelessWidget {
  static final Receipts receipts = new Receipts();

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Receipts',
      home: new NewReceiptWidget()
    );
  }
}

class NewReceiptWidget extends StatefulWidget {
  @override
  createState() => new NewReceiptState();
}

class NewReceiptState extends State<NewReceiptWidget> with WidgetsBindingObserver {

  String _apikey;
  Receipts _receipts;
  StreamSubscription<LocationData> _locationSubscription;

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
      case AppLifecycleState.detached:
        _receipts.save();
        _locationSubscription.cancel();
        break;
      case AppLifecycleState.resumed:
        _locationSubscription = _location.onLocationChanged.listen(getPlaces);
        break;
    }
  }

  getPlaces(LocationData location) async {
    try {
      // If the widget was removed from the tree while the asynchronous platform
      // message was in flight, we want to discard the reply rather than calling
      // setState to update our non-existent appearance.
      if (!mounted) return;

      if (_apikey == null)
        _apikey = json.decode(await DefaultAssetBundle.of(context).loadString('secret.json'))['apikey'];

      dynamic data;

      var uri = new Uri.https(
        'maps.googleapis.com', '/maps/api/place/nearbysearch/json', {
        'key': _apikey,
        'location': "${location.latitude},${location.longitude}",
        'rankby': 'distance'
      });

      http.Response response = await http.get(uri);
      data = json.decode(response.body);

      if (data != null)
        setState(() {
          try {
            for (var r in data['results'])
              _places.add(r['name']);
          } catch (e) {}
        });
    } catch (e) {
      setState(() {
        _places.add(e);
      });

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
          inputFormatters: <TextInputFormatter>[new FilteringTextInputFormatter.allow(new RegExp(r'^\d+\.?\d?\d?'))],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.headline5.apply(fontWeightDelta: 4),
          decoration: new InputDecoration(
            prefixIcon: new Icon(Icons.attach_money, color: Colors.black, size: Theme.of(context).textTheme.headline5.fontSize)),
        )),
        new IconButton(icon: new Icon(Icons.local_grocery_store), onPressed: (){ _addReceipt('Groceries');}),
        new IconButton(icon: new Icon(Icons.local_gas_station), onPressed: (){ _addReceipt('Fuel');}),
        new IconButton(icon: new Icon(Icons.restaurant), onPressed: (){ _addReceipt('Food/Drink');}),
        new IconButton(icon: new Icon(Icons.local_offer), onPressed: (){ _addReceipt('Uncategorised');}),
      ]),
      new Expanded(child: new ListView.builder(
        itemBuilder: (context, i) {
          if (i < _places.length)
            return _buildPlaceRow(_places.elementAt(i));

          return null;
        },
      )),
    ]);
  }

  Widget _buildPlaceRow(String place) {
    return new ListTile(
      title: new Text(
        place,
        style: Theme.of(context).textTheme.subtitle1.apply(fontWeightDelta: 4),
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
          new IconButton(icon: new Icon(Icons.share), onPressed: _share),
          new IconButton(icon: new Icon(Icons.list), onPressed: () {
            Navigator.push(context, new MaterialPageRoute(builder: (context) {
              return new CheckedReceiptsWidget();
            }));}),
        ]
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

  void _share() async {
    DateFormat formatter = new DateFormat('yyyy-MM-dd');

    String data = "";
    for(Receipt r in _receipts.current) {
      String date = formatter.format(r.date.toLocal());
      data += "$date,${r.value},${r.place.replaceAll(',', ' ')}\n";
    }
    Share.share(data);
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
      ]),
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

  _delete() async {
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
          ]
        );
      },
    );
  }
}
