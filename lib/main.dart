import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await HydratedStorage.build(
      storageDirectory: await getTemporaryDirectory());
  HydratedBlocOverrides.runZoned(
    () => runApp(App()),
    storage: storage,
  );
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BrightnessCubit(),
      child: AppView(),
    );
  }
}

class AppView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BrightnessCubit, Brightness>(
      builder: (context, brightness) {
        return MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: CounterPage(),
        );
      },
    );
  }
}

class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<CounterBloc>(
      create: (_) => CounterBloc(),
      child: CounterView(),
    );
  }
}

class CounterView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Counter')),
      body: BlocBuilder<CounterBloc, CounterListModel>(
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.counters?.length,
                  reverse: true,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      title: Text('${state.counters![index].count}',
                          style: textTheme.headline5),
                      subtitle: Text('${state.counters![index].createdAt}',
                          style: textTheme.headline6),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            child: const Icon(Icons.brightness_6),
            onPressed: () => context.read<BrightnessCubit>().toggleBrightness(),
          ),
          const SizedBox(height: 4),
          FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () {
              context.read<CounterBloc>().add(CounterIncrementPressed());
            },
          ),
          const SizedBox(height: 4),
          FloatingActionButton(
            child: const Icon(Icons.remove),
            onPressed: () {
              context.read<CounterBloc>().add(CounterDecrementPressed());
            },
          ),
          const SizedBox(height: 4),
          FloatingActionButton(
            child: const Icon(Icons.delete_forever),
            onPressed: () {
              HydratedBlocOverrides.current?.storage.clear();
            },
          ),
        ],
      ),
    );
  }
}

class CounterModel {
  CounterModel({this.count = 0, this.createdAt});
  final int count;
  final DateTime? createdAt;

  CounterModel.fromJson(Map<String, dynamic> json)
      : count = json['count'] as int,
        createdAt = json['createdAt'] == null
            ? null
            : DateTime.parse(json['createdAt'] as String);

  Map<String, dynamic> toJson() => {
        'count': count,
        'createdAt': createdAt?.toIso8601String(),
      };
}

class CounterListModel {
  CounterListModel({this.counters = const <CounterModel>[]});
  final List<CounterModel>? counters;

  CounterListModel.fromJson(Map<String, dynamic> json)
      : counters = (json['counters'] as List<dynamic>)
            .map((dynamic item) =>
                CounterModel.fromJson(item as Map<String, dynamic>))
            .toList();

  Map<String, dynamic> toJson() => {
        'counters':
            counters?.map((CounterModel item) => item.toJson()).toList(),
      };
}

abstract class CounterEvent {}

class CounterIncrementPressed extends CounterEvent {
  final int count;
  CounterIncrementPressed({this.count = 1});
}

class CounterDecrementPressed extends CounterEvent {
  final int count;
  CounterDecrementPressed({this.count = 1});
}

class CounterBloc extends HydratedBloc<CounterEvent, CounterListModel> {
  CounterBloc() : super(CounterListModel(counters: [CounterModel(count: 1)])) {
    on<CounterIncrementPressed>((event, emit) => emit(incrementCounter()));
    on<CounterDecrementPressed>((event, emit) => emit(decrementCounter()));
  }

  CounterListModel incrementCounter() {
    debugPrint('incrementCounter ${state.toJson()}');
    state.counters?.add(CounterModel(
        count: state.counters?.last.count ?? 0 + 2, createdAt: DateTime.now()));
    return state;
  }

  CounterListModel decrementCounter() {
    state.counters?.add(CounterModel(
        count: state.counters?.last.count ?? 0 - 1, createdAt: DateTime.now()));
    return state;
  }

  @override
  CounterListModel fromJson(Map<String, dynamic> json) =>
      CounterListModel.fromJson(json);

  @override
  Map<String, dynamic> toJson(CounterListModel state) => state.toJson();
}

class BrightnessCubit extends HydratedCubit<Brightness> {
  BrightnessCubit() : super(Brightness.light);

  void toggleBrightness() {
    emit(state == Brightness.light ? Brightness.dark : Brightness.light);
  }

  @override
  Brightness fromJson(Map<String, dynamic> json) {
    return Brightness.values[json['brightness'] as int];
  }

  @override
  Map<String, dynamic> toJson(Brightness state) {
    return <String, int>{'brightness': state.index};
  }
}
