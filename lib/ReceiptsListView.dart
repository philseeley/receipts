import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'Receipts.dart';

final TextStyle _biggerFont = const TextStyle(
    color: Colors.black, fontSize: 16.0, fontWeight: FontWeight.bold);
final TextStyle _biggestFont = const TextStyle(
    color: Colors.black, fontSize: 24.0, fontWeight: FontWeight.bold);

typedef void DismissAction(DismissDirection direction, Receipt receipt);

class ReceiptsListView extends StatefulWidget {
  final List<Receipt> _receipts;
  final IconData _swipeLeftIcon;
  final IconData _swipeRightIcon;
  final DismissAction _onDismissed;

  ReceiptsListView (this._receipts, this._swipeLeftIcon, this._swipeRightIcon, this._onDismissed);

  @override
  createState() => new ReceiptsListViewState(_receipts, _swipeLeftIcon, _swipeRightIcon, this._onDismissed);
}

class ReceiptsListViewState extends State<ReceiptsListView> {
  final List<Receipt> _receipts;
  final IconData _swipeLeftIcon;
  final IconData _swipeRightIcon;
  final DismissAction _onDismissed;

  ReceiptsListViewState(this._receipts, this._swipeLeftIcon, this._swipeRightIcon, this._onDismissed);

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

    return new Dismissible(
      key: new GlobalKey(),
        secondaryBackground: new ListTile(trailing: new Icon(_swipeLeftIcon)),
        background: new ListTile(leading: new Icon(_swipeRightIcon)),
      onDismissed: (direction){
        _onDismissed(direction, receipt);
        },
      direction: DismissDirection.horizontal,
      child: new Row(children: <Widget>[
        new Expanded(child: new ListTile(
          title: new Text(
            '${receipt.place}\n$formatted',
            style: _biggerFont,
          ),
        )),
        new Expanded(child: new ListTile(
          title: new Text(
            '\$ ${receipt.value.toStringAsFixed(2)}',
            style: _biggestFont,
            textAlign: TextAlign.right,
          ),
        ))

      ])
    );
  }
}
