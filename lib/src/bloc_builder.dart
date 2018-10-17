import 'package:flutter/widgets.dart';

import 'package:bloc/bloc.dart';

/// A function that will be run which takes the [BuildContext] and state
/// and is responsible for returning a [Widget] which is to be rendered.
/// This is analagous to the `builder` function in [StreamBuilder].
typedef Widget BlocWidgetBuilder<S>(BuildContext context, S state);

/// A Flutter widget which requires a [Bloc] and a [BlocWidgetBuilder] `builder` function.
/// [BlocBuilder] handles building the widget in response to new states.
/// BlocBuilder analagous to [StreamBuilder] but has simplified API
/// to reduce the amount of boilerplate code needed.
class BlocBuilder<S> extends StatefulWidget {
  final HasState<S> bloc;
  final BlocWidgetBuilder<S> builder;

  const BlocBuilder({Key key, @required this.bloc, @required this.builder})
      : assert(bloc != null),
        assert(builder != null),
        super(key: key);

  @override
  State<StatefulWidget> createState() => _BlocBuilderState(bloc, builder);
}

class _BlocBuilderState<S> extends State<BlocBuilder<S>> {
  final HasState<S> bloc;
  final BlocWidgetBuilder<S> builder;

  _BlocBuilderState(this.bloc, this.builder);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<S>(
      initialData: bloc.initialState,
      stream: bloc.state,
      builder: (BuildContext context, AsyncSnapshot<S> snapshot) {
        return builder(context, snapshot.data);
      },
    );
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }
}
