import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:meta/meta.dart';
import 'package:rx_command/rx_command.dart';

abstract class IBloc
{
  void dispose();
}

abstract class BaseBloc implements IBloc
{
  bool _disposed = false;
  bool get disposed => _disposed;

  @mustCallSuper
  void dispose() {
    _disposed = true;
  }
}

abstract class HasState<S> implements IBloc
{
  // class is a mixin
  factory HasState._() => null;

  final BehaviorSubject<S> _stateSubject = BehaviorSubject<S>();
  @protected BehaviorSubject<S> get stateSubject => _stateSubject;

  /// Returns [Stream] of states, receives the last one (if any) on subscription.
  /// Consumed by [BlocBuilder].
  Stream<S> get state => _stateSubject.stream;

  /// Returns the state before any events have been `dispatched`.
  @protected S get initialState => null;

  @protected void setState(S state) => stateSubject.add(state);

  @protected
  void disposeState() {
    _stateSubject.close();
  }
}

abstract class HasEvent<E> implements IBloc
{
  // class is a mixin
  factory HasEvent._() => null;

  final PublishSubject<E> _eventSubject = PublishSubject<E>();

  /// Takes an event and triggers `mapEventToState`.
  /// `Dispatch` may be called from the presentation layer or from within the Bloc.
  /// `Dispatch` notifies the [Bloc] of a new event.
  void dispatch(E event) {
    _eventSubject.sink.add(event);
  }

  /// Transform the `Stream<Event>` before `mapEventToState` is called.
  /// This allows for operations like `distinct()`, `debounce()`, etc... to be applied.
  @protected Stream<E> transform(Stream<E> events) => events;

  @protected
  void disposeEvent() {
    _eventSubject.close();
  }
}

abstract class SinkBloc extends BaseBloc {
  // waiting for CompositeSubscription https://github.com/ReactiveX/rxdart/pull/191/files/ae26e7b9ed63ed0832eac6362adb611f59588b8e
  @protected List<StreamSubscription> _disposables = List<StreamSubscription>();

  @override
  void dispose() {
    _disposables.forEach((d) => d.cancel());
    _disposables.clear();
    super.dispose();
  }

  void disposeWhenDone(StreamSubscription listen)
    => _disposables.add(listen);
}

abstract class SinkStateBloc<S> extends SinkBloc with HasState<S> {
  @override
  void dispose() {
    disposeState();
    super.dispose();
  }
}

abstract class EventStateBloc<E, S> extends SinkBloc with HasState<S>, HasEvent<E> {

  Observable<E> get _transformedEvents => (transform(_eventSubject) as Observable<E>);

  @protected
  Stream<OnEvent<T,S>> onEvent<T extends E>() =>
    _transformedEvents
      .where((evt) => evt is T) //TODO: isn't this just a transform ?
      .withLatestFrom(
        stateSubject.startWith(initialState), //TODO: what if null ?
        (E e, S s) => OnEvent(e as T,s)
      );

  @override
  void dispose() {
    disposeEvent();
    disposeState();
    super.dispose();
  }
}


/// Takes a [Stream] of events as input
/// and transforms them into a [Stream] of states as output.
abstract class Bloc<E, S> extends EventStateBloc<E, S> {

  Bloc() {
    _bindStateSubject();
  }

  /// Must be implemented when a class extends Bloc.
  /// Takes the current `state` and incoming `event` as arguments.
  /// `mapEventToState` is called whenever an event is dispatched by the presentation layer.
  /// `mapEventToState` must convert that event, along with the current state, into a new state
  /// and return the new state in the form of a [Stream] which is consumed by the presentation layer.
  @protected Stream<S> mapEventToState(S state, E event);

  void _bindStateSubject() {
    _transformedEvents
      .concatMap(
        (E ev) => mapEventToState(stateSubject.value ?? initialState, ev),
      )
      .forEach(setState);
  }
}

/*
abstract class RxBloc<E,S> extends SinkStateBloc<S>
{
  RxCommand<E,S> _command;
  @protected Stream<S> get result => _command;

  @protected S mapEventToState(S state, E event);

  RxBloc(RxCommand<E,S> _command) : super()
  {
    //_command = RxCommand.createSync((e) => mapEventToState(stateSubject.value, e));
    disposables.add(_command.listen(setState));
  }

  Stream<S> get state => _command;

  Stream<bool> get isExecuting => _command.isExecuting;

  void execute(E evt) => _command.execute(evt);
}
*/

class OnEvent<E, S> {
  E event;
  S lastState;
  OnEvent(E this.event, S this.lastState){}
}