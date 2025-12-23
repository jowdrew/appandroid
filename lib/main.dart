import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';
import 'features/expenses/data/repositories/expense_repository.dart';
import 'features/expenses/presentation/bloc/expenses_bloc.dart';
import 'features/expenses/presentation/bloc/expenses_event.dart';

/// Entry point of the expense tracking application.
///
/// This function ensures that Flutter binding is initialized before
/// accessing any plugins (such as sqflite) and wires up the
/// repository and BLoC layer before running the app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the repository which creates/opens the local database.
  final expenseRepository = ExpenseRepository();
  await expenseRepository.init();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: expenseRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => ExpensesBloc(expenseRepository)
              ..add(const ExpensesStarted()),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}