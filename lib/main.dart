import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:location/location.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'Receipts.dart';

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
  final TextStyle _biggerFont = const TextStyle(
      color: Colors.black, fontSize: 16.0, fontWeight: FontWeight.bold);
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
  dispose (){
    print('DISPASE');
    super.dispose();
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
    print('STATE:$state');
  }

  getPlaces(Map<String, double> location) async {
    dynamic data;
//    print(location);
    if(location['accuracy'] <= 20/2) {
      print('remove loc subscription');
      _locationSubscription.cancel();
    }
    try {
      var uri = new Uri.https(

/*    'maps.googleapis.com', '/maps/api/place/nearbysearch/json', {
        'key': 'AIzaSyCErmNo5wVAFa68O49BoihbeQz_Jtyk8Zk',
        'location': "-37.934747,145.038774",
        'radius': '20'
      });*/

      'maps.googleapis.com', '/maps/api/place/nearbysearch/json', {'key': 'AIzaSyCErmNo5wVAFa68O49BoihbeQz_Jtyk8Zk', 'location': "${location["latitude"]},${location["longitude"]}", 'radius': '20'});

      http.Response response = await http.get(uri);
      data = json.decode(response.body);
    } catch (e) {
    }

//    print('DATA:${data}');

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    if(data != null)
      setState(() {
//      _places.clear();
        for (var r in data['results']) _places.add(r['name']);
/*
      _places.add('test0');
      _places.add('test1');
      _places.add('test2');
*/
      });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text('Add Receipt'), actions: <Widget>[
        new IconButton(
          icon: new Icon(Icons.list),
          onPressed: () {
            Navigator.push(context, new MaterialPageRoute(builder: (context) {
              return new ReceiptsWidget();
            }));
          },
        )
      ]),
      body: _buildInput(),
    );
  }

  Widget _buildInput() {
    return new Column(children: <Widget>[
      new TextField(
        controller: _valueCtrl,
        autofocus: true,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.left,
        style: _biggerFont,
        decoration: new InputDecoration(
            labelText: '\$', contentPadding: new EdgeInsets.all(10.0)),
      ),
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
        setState(() {
          double value = null;
          try{
            value = double.parse(_valueCtrl.text);

          } catch (e) {}
          if(value != null) {
            _receipts.current.add(new Reciept(
                new DateTime.now(), place, value));

//            _receipts.save();
            SystemNavigator.pop();
//            exit(0);
//            Navigator.pop(context);
          }
        });
      },
    );
  }
}

class ReceiptsWidget extends StatefulWidget {
  @override
  createState() => new ReceiptsState();
}

class ReceiptsState extends State<ReceiptsWidget> {
  Receipts _receipts;

  final TextStyle _biggerFont = const TextStyle(
      color: Colors.black, fontSize: 16.0, fontWeight: FontWeight.bold);

  ReceiptsState()
  {
    _receipts = ReceiptsApp.receipts;
  }

/*
  @override
  void initState() {
    super.initState();
  }

*/
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Receipts'),
        actions: <Widget>[
          new IconButton(icon: new Icon(Icons.undo), onPressed: _undo),
        ],
      ),
      body: new ListView.builder(itemBuilder: (BuildContext context, int i) {
        if (i >= _receipts.current.length)
          return null;
        else
          return _buildReceiptRow(_receipts.current[i]);
      }),
    );
  }

  Widget _buildReceiptRow(Reciept receipt) {
    var formatter = new DateFormat('yyyy-MM-dd HH:mm');
    String formatted = formatter.format(receipt.date.toLocal());
    return new ListTile(
      title: new Text(
        '${formatted} ${receipt.place} ${receipt.value}',
        style: _biggerFont,
      ),
      onTap: () {
        setState(() {
          _receipts.current.remove(receipt);
          _receipts.checked.add(receipt);
        });
      },
    );
  }

  void _undo() {
    setState((){
      if(_receipts.checked.length > 0)
        _receipts.current.insert(0, _receipts.checked.removeLast());
    });
  }
}
