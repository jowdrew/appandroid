import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/money.dart';
import '../bloc/expenses_bloc.dart';
import '../bloc/expenses_event.dart';
import '../bloc/expenses_state.dart';
import '../widgets/add_expense_sheet.dart';

/// Main screen showing the dashboard and expense history.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpensesBloc, ExpensesState>(
      builder: (context, state) {
        // Localized month name in Spanish
        final monthLabel = DateFormat('MMMM yyyy', 'es').format(state.month);
        final entries = state.byCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Scaffold(
          appBar: AppBar(
            title: Text('Gastos • $monthLabel'),
            actions: [
              // Navigate to previous month
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Mes anterior',
                onPressed: () {
                  final prev =
                      DateTime(state.month.year, state.month.month - 1, 1);
                  context.read<ExpensesBloc>().add(ExpensesMonthChanged(prev));
                },
              ),
              // Navigate to next month
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Mes siguiente',
                onPressed: () {
                  final next =
                      DateTime(state.month.year, state.month.month + 1, 1);
                  context.read<ExpensesBloc>().add(ExpensesMonthChanged(next));
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final bloc = context.read<ExpensesBloc>();

              final result = await showModalBottomSheet<AddExpenseResult>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => const AddExpenseSheet(),
              );

              if (result != null) {
                bloc.add(ExpenseAdded(result.toExpense()));
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Registrar gasto'),
          ),
          body: SafeArea(
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async {
                      context.read<ExpensesBloc>().add(const ExpensesStarted());
                    },
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total del mes',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium,
                                    ),
                                    Chip(
                                      avatar: const Icon(Icons.trending_up),
                                      label: Text(DateFormat('LLLL')
                                          .format(state.month)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  formatMoney(state.total),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Top categorías',
                                  style:
                                      Theme.of(context).textTheme.labelMedium,
                                ),
                                const SizedBox(height: 8),
                                entries.isEmpty
                                    ? const Text(
                                        'Aún no hay gastos registrados.')
                                    : Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: entries.take(4).map((e) {
                                          return Chip(
                                            label: Text(
                                                '${e.key} • ${formatMoney(e.value)}'),
                                          );
                                        }).toList(),
                                      ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Historial',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        state.expenses.isEmpty
                            ? Card(
                                elevation: 0,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'Registra tu primer gasto con el botón “Registrar gasto”.',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              )
                            : Column(
                                children: state.expenses.map((e) {
                                  final dateLabel =
                                      DateFormat('dd/MM').format(e.date);
                                  final avatarColor = Theme.of(context)
                                      .colorScheme
                                      .primaryContainer;
                                  final avatarTextColor = Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer;
                                  final subtitle =
                                      e.note?.trim().isNotEmpty == true
                                          ? e.note!
                                          : (e.paymentMethod ?? 'Sin nota');

                                  return Card(
                                    elevation: 0,
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: avatarColor,
                                        child: Text(
                                          dateLabel,
                                          style: TextStyle(
                                              color: avatarTextColor,
                                              fontSize: 12),
                                        ),
                                      ),
                                      title: Text(e.category),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(subtitle),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat('EEE d', 'es')
                                                .format(e.date),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                    color: Theme.of(context)
                                                        .hintColor),
                                          ),
                                        ],
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            formatMoney(e.amount,
                                                currency: e.currency),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.bold),
                                          ),
                                          if (e.paymentMethod != null)
                                            Text(
                                              e.paymentMethod!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall,
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}
