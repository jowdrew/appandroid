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
        theme: buildAppTheme(),
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
        title: Text(_currentIndex == 0 ? 'Dashboard mensual' : 'Movimientos'),
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          return IndexedStack(
            index: _currentIndex,
            children: const [
              DashboardScreen(),
              MovementsScreen(),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddMovement(context),
        icon: const Icon(Icons.add),
        label: const Text('Agregar movimiento'),
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
            icon: Icon(Icons.swap_horiz_outlined),
            selectedIcon: Icon(Icons.swap_horiz),
            label: 'Movimientos',
          ),
        ],
      ),
    );
  }

  Future<void> _openAddMovement(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const AddMovementSheet(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ExpensesScope.of(context);
    final now = DateTime.now();
    final monthMovements = store.movementsForMonth(now);
    final previousMonthMovements = store.movementsForMonth(
      DateTime(now.year, now.month - 1, 1),
    );
    final incomeTotal = store.totalForType(monthMovements, MovementType.income);
    final expenseTotal = store.totalForType(monthMovements, MovementType.expense);
    final balance = incomeTotal - expenseTotal;
    final previousExpenseTotal =
        store.totalForType(previousMonthMovements, MovementType.expense);
    final diff = expenseTotal - previousExpenseTotal;
    final percentChange = previousExpenseTotal == 0
        ? 0.0
        : (diff / previousExpenseTotal * 100).clamp(-999, 999);
    final topExpenseCategories = store.topCategories(
      monthMovements.where((movement) => movement.type == MovementType.expense),
      count: 3,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text(
          DateFormat('MMMM yyyy', 'es_PE').format(now),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        _SummaryCard(
          incomeTotal: incomeTotal,
          expenseTotal: expenseTotal,
          balance: balance,
          previousExpenseTotal: previousExpenseTotal,
          percentChange: percentChange,
          diff: diff,
        ),
        const SizedBox(height: 20),
        _SectionHeader(
          title: 'Top categorías de gasto',
          subtitle: 'Lo más relevante de tu mes',
        ),
        const SizedBox(height: 12),
        _TopCategoriesList(categories: topExpenseCategories),
        const SizedBox(height: 20),
        _SectionHeader(
          title: 'Distribución del mes',
          subtitle: 'Comparte tu gasto por categorías',
        ),
        const SizedBox(height: 12),
        _CategoryChart(data: topExpenseCategories),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.incomeTotal,
    required this.expenseTotal,
    required this.balance,
    required this.previousExpenseTotal,
    required this.percentChange,
    required this.diff,
  });

  final double incomeTotal;
  final double expenseTotal;
  final double balance;
  final double previousExpenseTotal;
  final double percentChange;
  final double diff;

  @override
  Widget build(BuildContext context) {
    final currency = currencyFormatter();
    final isPositive = diff <= 0;
    final comparisonLabel = previousExpenseTotal == 0
        ? 'Sin datos del mes anterior'
        : '${percentChange >= 0 ? '+' : ''}${percentChange.toStringAsFixed(1)}% vs mes anterior';

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Resumen del mes',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Balance',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              currency.format(balance),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              balance >= 0
                  ? 'Tu balance es positivo'
                  : 'Balance negativo este mes',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _AmountTile(
                    label: 'Ingresos',
                    amount: incomeTotal,
                    icon: Icons.arrow_downward,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AmountTile(
                    label: 'Gastos',
                    amount: expenseTotal,
                    icon: Icons.arrow_upward,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isPositive
                    ? Theme.of(context).colorScheme.tertiaryContainer
                    : Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    isPositive ? Icons.trending_down : Icons.trending_up,
                    color: isPositive
                        ? Theme.of(context).colorScheme.tertiary
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
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountTile extends StatelessWidget {
  const _AmountTile({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final currency = currencyFormatter();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(
                  currency.format(amount),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
        ],
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              leading: CircleAvatar(
                backgroundColor: summary.category.color.withOpacity(0.2),
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
    final maxValue =
        data.map((item) => item.total).reduce((a, b) => a > b ? a : b);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
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
                          borderRadius: BorderRadius.circular(16),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class MovementsScreen extends StatefulWidget {
  const MovementsScreen({super.key});

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen> {
  MovementCategory? _selectedCategory;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String _searchQuery = '';
  MovementType? _selectedTypeFilter;

  @override
  Widget build(BuildContext context) {
    final store = ExpensesScope.of(context);
    final months = store.availableMonths();
    final availableCategories = store.categoriesForFilter(_selectedTypeFilter);
    if (_selectedCategory != null &&
        !availableCategories.contains(_selectedCategory)) {
      _selectedCategory = null;
    }
    final filtered = store.filteredMovements(
      month: _selectedMonth,
      category: _selectedCategory,
      type: _selectedTypeFilter,
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
              categories: availableCategories,
              selected: _selectedCategory,
              onChanged: (value) => setState(() => _selectedCategory = value),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SegmentedButton<MovementType>(
          segments: const [
            ButtonSegment(value: MovementType.expense, label: Text('Gasto')),
            ButtonSegment(value: MovementType.income, label: Text('Ingreso')),
          ],
          multiSelectionEnabled: false,
          emptySelectionAllowed: true,
          selected: _selectedTypeFilter == null
              ? <MovementType>{}
              : {_selectedTypeFilter!},
          onSelectionChanged: (selection) {
            setState(() {
              _selectedTypeFilter =
                  selection.isEmpty ? null : selection.first;
            });
          },
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
          const Text('No hay movimientos con estos filtros.')
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
                    (movement) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor:
                            movement.category.color.withOpacity(0.15),
                        child: Icon(movement.category.icon,
                            color: movement.category.color),
                      ),
                      title: Text(movement.category.label),
                      subtitle: Text(
                        movement.note?.isNotEmpty == true
                            ? movement.note!
                            : movement.paymentMethod ?? 'Sin nota',
                      ),
                      trailing: Text(
                        '${movement.type == MovementType.income ? '+' : '-'}${currency.format(movement.amount)}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: movement.type == MovementType.income
                                  ? Theme.of(context).colorScheme.tertiary
                                  : Theme.of(context).colorScheme.error,
                            ),
                      ),
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

  final List<MovementCategory> categories;
  final MovementCategory? selected;
  final ValueChanged<MovementCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<MovementCategory>(
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

class AddMovementSheet extends StatefulWidget {
  const AddMovementSheet({super.key});

  @override
  State<AddMovementSheet> createState() => _AddMovementSheetState();
}

class _AddMovementSheetState extends State<AddMovementSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _paymentController = TextEditingController();
  MovementCategory? _selectedCategory;
  MovementType _selectedType = MovementType.expense;
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
    final viewInsets = MediaQuery.of(context).viewInsets;
    final categories = store.categoriesForType(_selectedType);

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
          Text('Nuevo movimiento',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SegmentedButton<MovementType>(
            segments: const [
              ButtonSegment(value: MovementType.expense, label: Text('Gasto')),
              ButtonSegment(value: MovementType.income, label: Text('Ingreso')),
            ],
            selected: {_selectedType},
            onSelectionChanged: (selection) {
              setState(() {
                _selectedType = selection.first;
                _selectedCategory = null;
              });
            },
          ),
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
          Text('Categorías',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories
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
            onPressed: () => _saveMovement(context),
            child: const Text('Guardar movimiento'),
          ),
        ],
      ),
    );
  }

  void _saveMovement(BuildContext context) {
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

    store.addMovement(
      Movement(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: _selectedType,
        amount: amount,
        category: _selectedCategory!,
        date: _selectedDate,
        createdAt: DateTime.now(),
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

enum MovementType { expense, income }

class Movement {
  Movement({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.date,
    required this.createdAt,
    this.note,
    this.paymentMethod,
  });

  final String id;
  final MovementType type;
  final double amount;
  final MovementCategory category;
  final DateTime date;
  final DateTime createdAt;
  final String? note;
  final String? paymentMethod;
}

class MovementCategory {
  const MovementCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.type,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final MovementType type;
}

class CategorySummary {
  CategorySummary(this.category, this.total);

  final MovementCategory category;
  final double total;
}

class ExpensesStore extends ChangeNotifier {
  ExpensesStore(this._movements);

  factory ExpensesStore.demo() {
    final now = DateTime.now();
    final demo = <Movement>[
      Movement(
        id: '1',
        type: MovementType.expense,
        amount: 42.5,
        category: expenseCategories[0],
        date: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 1)),
        note: 'Cena rápida',
        paymentMethod: 'Tarjeta',
      ),
      Movement(
        id: '2',
        type: MovementType.expense,
        amount: 120,
        category: expenseCategories[1],
        date: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 2)),
        note: 'Supermercado',
        paymentMethod: 'Yape',
      ),
      Movement(
        id: '3',
        type: MovementType.expense,
        amount: 18,
        category: expenseCategories[2],
        date: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 2)),
        note: 'Bus',
      ),
      Movement(
        id: '4',
        type: MovementType.expense,
        amount: 65,
        category: expenseCategories[3],
        date: now.subtract(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 3)),
        note: 'Plan mensual',
      ),
      Movement(
        id: '5',
        type: MovementType.expense,
        amount: 30,
        category: expenseCategories[4],
        date: now.subtract(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 5)),
        note: 'Farmacia',
      ),
      Movement(
        id: '6',
        type: MovementType.expense,
        amount: 25,
        category: expenseCategories[0],
        date: now.subtract(const Duration(days: 6)),
        createdAt: now.subtract(const Duration(days: 6)),
        note: 'Café',
      ),
      Movement(
        id: '7',
        type: MovementType.expense,
        amount: 80,
        category: expenseCategories[5],
        date: now.subtract(const Duration(days: 8)),
        createdAt: now.subtract(const Duration(days: 8)),
        note: 'Ropa',
      ),
      Movement(
        id: '8',
        type: MovementType.expense,
        amount: 210,
        category: expenseCategories[1],
        date: now.subtract(const Duration(days: 12)),
        createdAt: now.subtract(const Duration(days: 12)),
        note: 'Compra grande',
      ),
      Movement(
        id: '9',
        type: MovementType.expense,
        amount: 55,
        category: expenseCategories[2],
        date: now.subtract(const Duration(days: 15)),
        createdAt: now.subtract(const Duration(days: 15)),
        note: 'Taxi',
      ),
      Movement(
        id: '10',
        type: MovementType.expense,
        amount: 16,
        category: expenseCategories[4],
        date: now.subtract(const Duration(days: 17)),
        createdAt: now.subtract(const Duration(days: 17)),
        note: 'Vitaminas',
      ),
      Movement(
        id: '11',
        type: MovementType.expense,
        amount: 95,
        category: expenseCategories[3],
        date: DateTime(now.year, now.month - 1, 10),
        createdAt: DateTime(now.year, now.month - 1, 10),
        note: 'Streaming',
      ),
      Movement(
        id: '12',
        type: MovementType.expense,
        amount: 60,
        category: expenseCategories[0],
        date: DateTime(now.year, now.month - 1, 12),
        createdAt: DateTime(now.year, now.month - 1, 12),
        note: 'Almuerzo',
      ),
      Movement(
        id: '13',
        type: MovementType.income,
        amount: 2200,
        category: incomeCategories[0],
        date: now.subtract(const Duration(days: 4)),
        createdAt: now.subtract(const Duration(days: 4)),
        note: 'Sueldo',
      ),
      Movement(
        id: '14',
        type: MovementType.income,
        amount: 450,
        category: incomeCategories[1],
        date: now.subtract(const Duration(days: 9)),
        createdAt: now.subtract(const Duration(days: 9)),
        note: 'Proyecto diseño',
      ),
      Movement(
        id: '15',
        type: MovementType.income,
        amount: 120,
        category: incomeCategories[4],
        date: now.subtract(const Duration(days: 13)),
        createdAt: now.subtract(const Duration(days: 13)),
        note: 'Regalo familiar',
      ),
    ];
    return ExpensesStore(demo);
  }

  final List<Movement> _movements;

  List<Movement> get movements => List.unmodifiable(_movements);

  List<MovementCategory> categoriesForType(MovementType type) {
    return type == MovementType.expense ? expenseCategories : incomeCategories;
  }

  List<MovementCategory> categoriesForFilter(MovementType? type) {
    if (type == null) {
      return [...expenseCategories, ...incomeCategories];
    }
    return categoriesForType(type);
  }

  void addMovement(Movement movement) {
    _movements.insert(0, movement);
    notifyListeners();
  }

  List<Movement> movementsForMonth(DateTime month) {
    return _movements.where((movement) {
      return movement.date.year == month.year &&
          movement.date.month == month.month;
    }).toList();
  }

  double totalFor(List<Movement> movements) {
    return movements.fold(0, (sum, item) {
      return item.type == MovementType.income
          ? sum + item.amount
          : sum - item.amount;
    });
  }

  double totalForType(List<Movement> movements, MovementType type) {
    return movements
        .where((movement) => movement.type == type)
        .fold(0, (sum, item) => sum + item.amount);
  }

  List<CategorySummary> topCategories(Iterable<Movement> movements,
      {int count = 3}) {
    final totals = <MovementCategory, double>{};
    for (final movement in movements) {
      totals.update(movement.category, (value) => value + movement.amount,
          ifAbsent: () => movement.amount);
    }
    final summaries = totals.entries
        .map((entry) => CategorySummary(entry.key, entry.value))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return summaries.take(count).toList();
  }

  List<DateTime> availableMonths() {
    final months = <DateTime>{};
    for (final movement in _movements) {
      months.add(DateTime(movement.date.year, movement.date.month));
    }
    months.add(DateTime(DateTime.now().year, DateTime.now().month));
    final list = months.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }

  List<Movement> filteredMovements({
    required DateTime month,
    MovementCategory? category,
    MovementType? type,
    String query = '',
  }) {
    final lower = query.trim().toLowerCase();
    return _movements.where((movement) {
      final matchesMonth = movement.date.year == month.year &&
          movement.date.month == month.month;
      final matchesCategory =
          category == null || movement.category == category;
      final matchesType = type == null || movement.type == type;
      final matchesQuery = lower.isEmpty ||
          movement.category.label.toLowerCase().contains(lower) ||
          (movement.note?.toLowerCase().contains(lower) ?? false);
      return matchesMonth && matchesCategory && matchesType && matchesQuery;
    }).toList();
  }

  Map<DateTime, List<Movement>> groupByDay(List<Movement> movements) {
    final map = <DateTime, List<Movement>>{};
    for (final movement in movements) {
      final day =
          DateTime(movement.date.year, movement.date.month, movement.date.day);
      map.putIfAbsent(day, () => []).add(movement);
    }
    final entries = map.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
    return Map.fromEntries(entries);
  }
}

class ExpensesScope extends InheritedNotifier<ExpensesStore> {
  const ExpensesScope({
    super.key,
    required super.notifier,
    required super.child,
  });

  static ExpensesStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ExpensesScope>();
    assert(scope != null, 'ExpensesScope not found in context');
    return scope!.notifier!;
  }
}

final expenseCategories = <MovementCategory>[
  MovementCategory(
    id: 'food',
    label: 'Comida',
    icon: Icons.restaurant,
    color: Colors.orange,
    type: MovementType.expense,
  ),
  MovementCategory(
    id: 'grocery',
    label: 'Supermercado',
    icon: Icons.local_grocery_store,
    color: Colors.green,
    type: MovementType.expense,
  ),
  MovementCategory(
    id: 'transport',
    label: 'Transporte',
    icon: Icons.directions_car,
    color: Colors.blue,
    type: MovementType.expense,
  ),
  MovementCategory(
    id: 'subscriptions',
    label: 'Suscripciones',
    icon: Icons.subscriptions,
    color: Colors.purple,
    type: MovementType.expense,
  ),
  MovementCategory(
    id: 'health',
    label: 'Salud',
    icon: Icons.local_hospital,
    color: Colors.redAccent,
    type: MovementType.expense,
  ),
  MovementCategory(
    id: 'shopping',
    label: 'Compras',
    icon: Icons.shopping_bag,
    color: Colors.teal,
    type: MovementType.expense,
  ),
];

final incomeCategories = <MovementCategory>[
  MovementCategory(
    id: 'salary',
    label: 'Salario',
    icon: Icons.account_balance_wallet,
    color: Colors.indigo,
    type: MovementType.income,
  ),
  MovementCategory(
    id: 'freelance',
    label: 'Freelance',
    icon: Icons.work_outline,
    color: Colors.lightBlue,
    type: MovementType.income,
  ),
  MovementCategory(
    id: 'sales',
    label: 'Ventas',
    icon: Icons.storefront,
    color: Colors.teal,
    type: MovementType.income,
  ),
  MovementCategory(
    id: 'refund',
    label: 'Reembolso',
    icon: Icons.replay_circle_filled,
    color: Colors.green,
    type: MovementType.income,
  ),
  MovementCategory(
    id: 'gift',
    label: 'Regalo',
    icon: Icons.card_giftcard,
    color: Colors.pinkAccent,
    type: MovementType.income,
  ),
  MovementCategory(
    id: 'other',
    label: 'Otros',
    icon: Icons.more_horiz,
    color: Colors.blueGrey,
    type: MovementType.income,
  ),
];

NumberFormat currencyFormatter() {
  return NumberFormat.simpleCurrency(locale: 'es_PE', name: 'PEN');
}

ThemeData buildAppTheme() {
  const seedColor = Color(0xFF7D6CF2);
  const background = Color(0xFFF6F5FB);
  const surface = Colors.white;
  const positive = Color(0xFF7FE7C4);
  const negative = Color(0xFFFF8A8A);
  const neutral = Color(0xFF8EC5FF);
  const container = Color(0xFFEDE9FF);

  final colorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.light,
    primary: seedColor,
    secondary: neutral,
    tertiary: positive,
    error: negative,
    surface: surface,
    background: background,
    primaryContainer: container,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: background,
    fontFamily: 'Roboto',
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1F1D2B),
      ),
    ),
    cardTheme: CardTheme(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: Color(0xFF6D6A7C),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: container,
      selectedColor: seedColor.withOpacity(0.15),
      labelStyle: const TextStyle(fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1F1D2B),
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1F1D2B),
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1F1D2B),
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Color(0xFF5D5A6F),
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: Color(0xFF8C889B),
      ),
      labelLarge: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF8C889B),
      ),
      labelMedium: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6D6A7C),
      ),
    ),
  );
}
