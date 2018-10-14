import 'dart:async';

import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';
import 'package:rxdart/src/transformers/do.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  final CounterBloc _counterBloc = CounterBloc();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
      bloc: _counterBloc,
      builder: ((
        BuildContext context,
        int count,
      ) {
        return MaterialApp(
          title: 'Flutter Demo',
          home: Scaffold(
            appBar: AppBar(title: Text('Counter')),
            body: Center(
              child: Text(
                '$count',
                style: TextStyle(fontSize: 24.0),
              ),
            ),
            floatingActionButton: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 5.0),
                  child: FloatingActionButton(
                    child: Icon(Icons.add),
                    onPressed: _counterBloc.increment,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 5.0),
                  child: FloatingActionButton(
                    child: Icon(Icons.remove),
                    onPressed: _counterBloc.decrement,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

abstract class CounterEvent {}

class IncrementCounter extends CounterEvent {}

class DecrementCounter extends CounterEvent {}

class CounterBloc extends RxBloc<CounterEvent, int> {
  int get initialState => 0;

  CounterBloc(){
    disposables.add(
      onAction<IncrementCounter>()
        .map((action) => action.lastState += 1)
        .listen(setState)
    );

    disposables.add(
      onAction<DecrementCounter>()
        .map((action) => action.lastState -= 1)
        .listen(setState)
    );
  }

  void increment() => dispatch(IncrementCounter());

  void decrement() => dispatch(DecrementCounter());

  /*
  // just for debugging info
  @override
  Stream<CounterEvent> transform(Stream<CounterEvent> events) {
    return events
      .transform(new DoStreamTransformer<CounterEvent>(
          onData: print,
          //onError: (CounterEvent e, StackTrace s) => print("Oh no!"),
          //onDone: () => print("Done")
      )
    );
  }*/
}