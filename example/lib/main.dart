import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:rxdart/transformers.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  final CounterBloc _counterBloc = CounterBloc();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      initialData: _counterBloc.initialState,
      stream: _counterBloc.state,
      builder: (context, snapshot) {
        return MaterialApp(
          title: 'Flutter Demo',
          home: Scaffold(
            appBar: AppBar(title: Text('Counter')),
            body: Center(
              child: Text(
                snapshot.data.toString(),
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
      },
    );
  }
}

abstract class CounterEvent {}

class IncrementCounter extends CounterEvent {}

class DecrementCounter extends CounterEvent {}

class CounterBloc extends EventStateBloc<CounterEvent, int> {

  int get initialState => 1;

  CounterBloc(){

    var autoResetTimer = Stream.periodic(const Duration(seconds: 5), (v) => 0);

    disposeWhenDone(
      Observable.merge([
        onEvent<IncrementCounter>().map((action) => action.lastState += 1),
        onEvent<DecrementCounter>().map((action) => action.lastState -= 1),
        autoResetTimer
      ])
      .listen(setState)
    );
  }

  void increment() => dispatch(IncrementCounter());

  void decrement() => dispatch(DecrementCounter());

  // just for debugging info
  @override
  Stream<CounterEvent> transform(Stream<CounterEvent> events) {
    return events
      .transform(DoStreamTransformer<CounterEvent>(
          onData: print,
          //onError: (CounterEvent e, StackTrace s) => print("Oh no!"),
          //onDone: () => print("Done")
      )
    );
  }
}