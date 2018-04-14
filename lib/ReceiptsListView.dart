import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'Receipts.dart';

final TextStyle _biggerFont = const TextStyle(
    color: Colors.black, fontSize: 16.0, fontWeight: FontWeight.bold);
final TextStyle _biggestFont = const TextStyle(
    color: Colors.black, fontSize: 24.0, fontWeight: FontWeight.bold);

class ReceiptsListView extends StatefulWidget {
  final List<Receipt> _receipts;
  final ValueChanged<Receipt> _onTap;

  ReceiptsListView (this._receipts, this._onTap);

  @override
  createState() => new ReceiptsListViewState(_receipts, _onTap);
}

class ReceiptsListViewState extends State<ReceiptsListView> {
  final List<Receipt> _receipts;
  final ValueChanged<Receipt> _onTap;

  ReceiptsListViewState(this._receipts, this._onTap);

  @override
  Widget build(BuildContext context) {
    return new ListView.builder(itemBuilder: (BuildContext context, int i) {
        if (i >= _receipts.length)
          return null;
        else
          return _buildReceiptRow(_receipts[i]);
      });
    }

  Widget _buildReceiptRow(Receipt receipt) {
    var formatter = new DateFormat('yyyy-MM-dd HH:mm');
    String formatted = formatter.format(receipt.date.toLocal());
    return new Row(
      children: <Widget>[new Expanded(child:
    new ListTile(
    title: new Text(
    '${receipt.place}\n$formatted',
      style: _biggerFont,
    ),
    )),
      new Expanded(child:
      new ListTile(
        title: new Text(
          '\$ ${receipt.value.toStringAsFixed(2)}',
          style: _biggestFont,
          textAlign: TextAlign.right,
        ),
        onTap: () {
          setState(() {
            if(_onTap != null)
              _onTap(receipt);
          });
        },
      ))

      ]
    );
  }
}
