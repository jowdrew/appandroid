import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'es_PE';
  await initializeDateFormatting('es_PE', null);

  runApp(const ExpensesApp());
}

class ExpensesApp extends StatelessWidget {
  const ExpensesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ExpensesScope(
      notifier: ExpensesStore.demo(),
      child: MaterialApp(
        title: 'Gastos',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        locale: const Locale('es', 'PE'),
        supportedLocales: const [Locale('es', 'PE')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const HomeShell(),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final store = ExpensesScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'Dashboard mensual' : 'Historial'),
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          return IndexedStack(
            index: _currentIndex,
            children: const [
              DashboardScreen(),
              HistoryScreen(),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddExpense(context),
        icon: const Icon(Icons.add),
        label: const Text('Agregar gasto'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Historial',
          ),
        ],
      ),
    );
  }

  Future<void> _openAddExpense(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const AddExpenseSheet(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ExpensesScope.of(context);
    final now = DateTime.now();
    final monthExpenses = store.expensesForMonth(now);
    final previousMonthExpenses = store.expensesForMonth(
      DateTime(now.year, now.month - 1, 1),
    );
    final total = store.totalFor(monthExpenses);
    final previousTotal = store.totalFor(previousMonthExpenses);
    final diff = total - previousTotal;
    final percentChange = previousTotal == 0
        ? 0.0
        : (diff / previousTotal * 100).clamp(-999, 999);
    final topCategories = store.topCategories(monthExpenses, count: 3);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SummaryCard(
          total: total,
          previousTotal: previousTotal,
          percentChange: percentChange,
          diff: diff,
        ),
        const SizedBox(height: 16),
        Text('Top categorías', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _TopCategoriesList(categories: topCategories),
        const SizedBox(height: 16),
        Text('Distribución del mes',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _CategoryChart(data: topCategories),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.total,
    required this.previousTotal,
    required this.percentChange,
    required this.diff,
  });

  final double total;
  final double previousTotal;
  final double percentChange;
  final double diff;

  @override
  Widget build(BuildContext context) {
    final currency = currencyFormatter();
    final comparisonLabel = previousTotal == 0
        ? 'Sin datos del mes anterior'
        : '${percentChange >= 0 ? '+' : ''}${percentChange.toStringAsFixed(1)}% vs mes anterior';

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total del mes',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(
              currency.format(total),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  diff >= 0 ? Icons.trending_up : Icons.trending_down,
                  color: diff >= 0
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    comparisonLabel,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopCategoriesList extends StatelessWidget {
  const _TopCategoriesList({required this.categories});

  final List<CategorySummary> categories;

  @override
  Widget build(BuildContext context) {
    final currency = currencyFormatter();
    if (categories.isEmpty) {
      return const Text('Aún no hay gastos en este mes.');
    }
    return Column(
      children: categories
          .map(
            (summary) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: summary.category.color.withOpacity(0.15),
                child: Icon(summary.category.icon, color: summary.category.color),
              ),
              title: Text(summary.category.label),
              trailing: Text(
                currency.format(summary.total),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  const _CategoryChart({required this.data});

  final List<CategorySummary> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Text('Registra gastos para ver el gráfico.');
    }
    final maxValue = data.map((item) => item.total).reduce((a, b) => a > b ? a : b);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: data
              .map(
                (summary) => Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 80 * (summary.total / maxValue),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: summary.category.color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        summary.category.label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  ExpenseCategory? _selectedCategory;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final store = ExpensesScope.of(context);
    final months = store.availableMonths();
    final filtered = store.filteredExpenses(
      month: _selectedMonth,
      category: _selectedCategory,
      query: _searchQuery,
    );
    final grouped = store.groupByDay(filtered);
    final currency = currencyFormatter();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MonthFilter(
              months: months,
              selected: _selectedMonth,
              onChanged: (value) => setState(() => _selectedMonth = value),
            ),
            _CategoryFilter(
              categories: store.categories,
              selected: _selectedCategory,
              onChanged: (value) => setState(() => _selectedCategory = value),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Buscar por nota o categoría',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        const SizedBox(height: 16),
        if (grouped.isEmpty)
          const Text('No hay gastos con estos filtros.')
        else
          ...grouped.entries.map(
            (entry) {
              final total = store.totalFor(entry.value);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('EEEE d MMM', 'es_PE').format(entry.key),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        currency.format(total),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const Divider(),
                  ...entry.value.map(
                    (expense) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor:
                            expense.category.color.withOpacity(0.15),
                        child: Icon(expense.category.icon,
                            color: expense.category.color),
                      ),
                      title: Text(expense.category.label),
                      subtitle: Text(
                        expense.note?.isNotEmpty == true
                            ? expense.note!
                            : expense.paymentMethod ?? 'Sin nota',
                      ),
                      trailing: Text(currency.format(expense.amount)),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _MonthFilter extends StatelessWidget {
  const _MonthFilter({
    required this.months,
    required this.selected,
    required this.onChanged,
  });

  final List<DateTime> months;
  final DateTime selected;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<DateTime>(
      value: selected,
      decoration: const InputDecoration(
        labelText: 'Mes',
        border: OutlineInputBorder(),
      ),
      items: months
          .map(
            (month) => DropdownMenuItem(
              value: month,
              child: Text(DateFormat('MMMM yyyy', 'es_PE').format(month)),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  final List<ExpenseCategory> categories;
  final ExpenseCategory? selected;
  final ValueChanged<ExpenseCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ExpenseCategory>(
      value: selected,
      decoration: const InputDecoration(
        labelText: 'Categoría',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('Todas'),
        ),
        ...categories.map(
          (category) => DropdownMenuItem(
            value: category,
            child: Text(category.label),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class AddExpenseSheet extends StatefulWidget {
  const AddExpenseSheet({super.key});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _paymentController = TextEditingController();
  ExpenseCategory? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _paymentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ExpensesScope.of(context);
    final recent = store.recentCategories();
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: viewInsets.bottom + 24,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text('Nuevo gasto', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Monto',
              prefixText: 'S/ ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text('Categorías recientes',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recent.isEmpty
                ? [const Text('Aún no hay recientes.')]
                : recent
                    .map(
                      (category) => ChoiceChip(
                        label: Text(category.label),
                        selected: _selectedCategory == category,
                        avatar: Icon(category.icon, size: 18),
                        onSelected: (_) => setState(() {
                          _selectedCategory = category;
                        }),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 16),
          Text('Todas las categorías',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: store.categories
                .map(
                  (category) => FilterChip(
                    label: Text(category.label),
                    selected: _selectedCategory == category,
                    avatar: Icon(category.icon, size: 18),
                    onSelected: (_) => setState(() {
                      _selectedCategory = category;
                    }),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: Text(DateFormat('EEEE d MMMM', 'es_PE').format(_selectedDate)),
            trailing: TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(DateTime.now().year - 1),
                  lastDate: DateTime(DateTime.now().year + 1),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              child: const Text('Cambiar'),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Nota (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _paymentController,
            decoration: const InputDecoration(
              labelText: 'Método de pago (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => _saveExpense(context),
            child: const Text('Guardar gasto'),
          ),
        ],
      ),
    );
  }

  void _saveExpense(BuildContext context) {
    final store = ExpensesScope.of(context);
    final raw = _amountController.text.replaceAll(',', '.');
    final amount = double.tryParse(raw);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto válido.')),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una categoría.')),
      );
      return;
    }

    store.addExpense(
      Expense(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        category: _selectedCategory!,
        date: _selectedDate,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        paymentMethod: _paymentController.text.trim().isEmpty
            ? null
            : _paymentController.text.trim(),
      ),
    );

    Navigator.of(context).pop();
  }
}

class Expense {
  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    this.paymentMethod,
  });

  final String id;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String? note;
  final String? paymentMethod;
}

class ExpenseCategory {
  const ExpenseCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color color;
}

class CategorySummary {
  CategorySummary(this.category, this.total);

  final ExpenseCategory category;
  final double total;
}

class ExpensesStore extends ChangeNotifier {
  ExpensesStore(this._expenses);

  factory ExpensesStore.demo() {
    final categories = defaultCategories;
    final now = DateTime.now();
    final demo = <Expense>[
      Expense(
        id: '1',
        amount: 42.5,
        category: categories[0],
        date: now.subtract(const Duration(days: 1)),
        note: 'Cena rápida',
        paymentMethod: 'Tarjeta',
      ),
      Expense(
        id: '2',
        amount: 120,
        category: categories[1],
        date: now.subtract(const Duration(days: 2)),
        note: 'Supermercado',
        paymentMethod: 'Yape',
      ),
      Expense(
        id: '3',
        amount: 18,
        category: categories[2],
        date: now.subtract(const Duration(days: 2)),
        note: 'Bus',
      ),
      Expense(
        id: '4',
        amount: 65,
        category: categories[3],
        date: now.subtract(const Duration(days: 3)),
        note: 'Plan mensual',
      ),
      Expense(
        id: '5',
        amount: 30,
        category: categories[4],
        date: now.subtract(const Duration(days: 5)),
        note: 'Farmacia',
      ),
      Expense(
        id: '6',
        amount: 25,
        category: categories[0],
        date: now.subtract(const Duration(days: 6)),
        note: 'Café',
      ),
      Expense(
        id: '7',
        amount: 80,
        category: categories[5],
        date: now.subtract(const Duration(days: 8)),
        note: 'Ropa',
      ),
      Expense(
        id: '8',
        amount: 210,
        category: categories[1],
        date: now.subtract(const Duration(days: 12)),
        note: 'Compra grande',
      ),
      Expense(
        id: '9',
        amount: 55,
        category: categories[2],
        date: now.subtract(const Duration(days: 15)),
        note: 'Taxi',
      ),
      Expense(
        id: '10',
        amount: 16,
        category: categories[4],
        date: now.subtract(const Duration(days: 17)),
        note: 'Vitaminas',
      ),
      Expense(
        id: '11',
        amount: 95,
        category: categories[3],
        date: DateTime(now.year, now.month - 1, 10),
        note: 'Streaming',
      ),
      Expense(
        id: '12',
        amount: 60,
        category: categories[0],
        date: DateTime(now.year, now.month - 1, 12),
        note: 'Almuerzo',
      ),
    ];
    return ExpensesStore(demo);
  }

  final List<Expense> _expenses;

  List<Expense> get expenses => List.unmodifiable(_expenses);

  List<ExpenseCategory> get categories => defaultCategories;

  void addExpense(Expense expense) {
    _expenses.insert(0, expense);
    notifyListeners();
  }

  List<Expense> expensesForMonth(DateTime month) {
    return _expenses.where((expense) {
      return expense.date.year == month.year && expense.date.month == month.month;
    }).toList();
  }

  double totalFor(List<Expense> expenses) {
    return expenses.fold(0, (sum, item) => sum + item.amount);
  }

  List<CategorySummary> topCategories(List<Expense> expenses, {int count = 3}) {
    final totals = <ExpenseCategory, double>{};
    for (final expense in expenses) {
      totals.update(expense.category, (value) => value + expense.amount,
          ifAbsent: () => expense.amount);
    }
    final summaries = totals.entries
        .map((entry) => CategorySummary(entry.key, entry.value))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return summaries.take(count).toList();
  }

  List<DateTime> availableMonths() {
    final months = <DateTime>{};
    for (final expense in _expenses) {
      months.add(DateTime(expense.date.year, expense.date.month));
    }
    months.add(DateTime(DateTime.now().year, DateTime.now().month));
    final list = months.toList()
      ..sort((a, b) => b.compareTo(a));
    return list;
  }

  List<Expense> filteredExpenses({
    required DateTime month,
    ExpenseCategory? category,
    String query = '',
  }) {
    final lower = query.trim().toLowerCase();
    return _expenses.where((expense) {
      final matchesMonth =
          expense.date.year == month.year && expense.date.month == month.month;
      final matchesCategory =
          category == null || expense.category == category;
      final matchesQuery = lower.isEmpty ||
          expense.category.label.toLowerCase().contains(lower) ||
          (expense.note?.toLowerCase().contains(lower) ?? false);
      return matchesMonth && matchesCategory && matchesQuery;
    }).toList();
  }

  Map<DateTime, List<Expense>> groupByDay(List<Expense> expenses) {
    final map = <DateTime, List<Expense>>{};
    for (final expense in expenses) {
      final day = DateTime(expense.date.year, expense.date.month, expense.date.day);
      map.putIfAbsent(day, () => []).add(expense);
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return Map.fromEntries(entries);
  }

  List<ExpenseCategory> recentCategories({int count = 3}) {
    final seen = <String, ExpenseCategory>{};
    for (final expense in _expenses) {
      if (!seen.containsKey(expense.category.id)) {
        seen[expense.category.id] = expense.category;
      }
      if (seen.length >= count) break;
    }
    return seen.values.toList();
  }
}

class ExpensesScope extends InheritedNotifier<ExpensesStore> {
  const ExpensesScope({
    super.key,
    required super.notifier,
    required super.child,
  });

  static ExpensesStore of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ExpensesScope>();
    assert(scope != null, 'ExpensesScope not found in context');
    return scope!.notifier!;
  }
}

final defaultCategories = <ExpenseCategory>[
  ExpenseCategory(
    id: 'food',
    label: 'Comida',
    icon: Icons.restaurant,
    color: Colors.orange,
  ),
  ExpenseCategory(
    id: 'grocery',
    label: 'Supermercado',
    icon: Icons.local_grocery_store,
    color: Colors.green,
  ),
  ExpenseCategory(
    id: 'transport',
    label: 'Transporte',
    icon: Icons.directions_car,
    color: Colors.blue,
  ),
  ExpenseCategory(
    id: 'subscriptions',
    label: 'Suscripciones',
    icon: Icons.subscriptions,
    color: Colors.purple,
  ),
  ExpenseCategory(
    id: 'health',
    label: 'Salud',
    icon: Icons.local_hospital,
    color: Colors.redAccent,
  ),
  ExpenseCategory(
    id: 'shopping',
    label: 'Compras',
    icon: Icons.shopping_bag,
    color: Colors.teal,
  ),
];

NumberFormat currencyFormatter() {
  return NumberFormat.simpleCurrency(locale: 'es_PE', name: 'PEN');
}
