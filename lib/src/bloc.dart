import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:meta/meta.dart';


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

class HasState<S> extends Object implements IBloc
{
  final BehaviorSubject<S> _stateSubject = BehaviorSubject<S>();
  @protected BehaviorSubject<S> get stateSubject => _stateSubject;

  /// Returns [Stream] of states, receives the last one (if any) on subscription.
  /// Consumed by [BlocBuilder].
  Stream<S> get state => _stateSubject;

  /// Returns the state before any events have been `dispatched`.
  @protected S get initialState => null;

  @protected void setState(S state) => stateSubject.add(state);

  void disposeState() {
    _stateSubject.close();
  }

  @override
  void dispose() {
    disposeState();
  }
}

class HasEvent<E> extends Object implements IBloc
{
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

  void disposeEvent() {
    _eventSubject.close();
  }

  @override
  void dispose() {
    disposeEvent();
  }
}

abstract class SinkBloc extends BaseBloc {
  // waiting for CompositeSubscription https://github.com/ReactiveX/rxdart/pull/191/files/ae26e7b9ed63ed0832eac6362adb611f59588b8e
  @protected List<StreamSubscription> disposables = List<StreamSubscription>();

  @override
  void dispose() {
    disposables.forEach((d) => d.cancel());
    disposables.clear();
    super.dispose();
  }
}

abstract class SinkStateBloc<S> extends SinkBloc with HasState<S> {
  @override
  void dispose() {
    (this as HasState).dispose();
    //disposeState();
    super.dispose();
  }
}

abstract class EventStateBloc<E, S> extends SinkBloc with HasState<S>, HasEvent<E> {
  Stream<OnEvent<T,S>> onEvent<T extends E>()
  => _eventSubject
      .where((evt) => evt is T) //TODO: isn't this just a transform ?
      .withLatestFrom(
        stateSubject.startWith(initialState), //TODO: what if null ?
        (E e, S s) => OnEvent(e as T,s)
      );

  @override
  void dispose() {
    (this as HasState).dispose();
    (this as HasEvent).dispose();
    //disposeEvent();
    //disposeState();
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
  Stream<S> mapEventToState(S state, E event);

  void _bindStateSubject() {
    (transform(_eventSubject) as Observable<E>)
    .concatMap(
      (E event) => mapEventToState(stateSubject.value ?? initialState, event),
    )
    .forEach(
      (S state) {
        setState(state);
      },
    );
  }
}

class OnEvent<E, S> {
  E event;
  S lastState;
  OnEvent(E this.event, S this.lastState){}
}