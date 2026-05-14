import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/widgets/dark_app_bar.dart';
import 'package:reminder_app/data/period_repository.dart';
import 'package:reminder_app/features/home/create_period_screen.dart';
import 'package:reminder_app/models/period.dart';

class PeriodScreen extends StatefulWidget{
  const PeriodScreen({super.key});

  @override
  State<PeriodScreen> createState() => _PeriodScreenState();
}

class _PeriodScreenState extends State<PeriodScreen>{
  final _repo = PeriodRepository();

  String _formatDate(DateTime date){
    final m = date.month.toString().padLeft(2,'0');
    final d = date.day.toString().padLeft(2, '0');
    return "$m/$d/${date.year}";
  }

  Future<void> _confirmDelete(Period period) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          "Eliminar periodo",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "¿Seguro que deseas eliminar \"${period.name}\"? Esta acción no se puede deshacer.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: const Text("Cancelar", style: TextStyle(color: Colors.white70))
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Eliminar", style: TextStyle(color: Colors.redAccent))
          ),
        ],
      )
    );

    if(confirmed != true) return;
    if(period.id == null) return;

    try{
      await _repo.delete(period.id!);
      if(!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Periodo eliminado"))
      );
    } catch (e){
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al eliminar: $e")),
      );
    }
  }

  void _openCreate(){
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => const CreatePeriodScreen()),
    );
  }

  void _openEdit(Period period){
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => CreatePeriodScreen(period: period)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const DarkAppBar(title: "Periodos"),
      body: StreamBuilder<List<Period>>(
        stream: _repo.watchAll(),
        builder: (context, snapshot){
          if(snapshot.connectionState == ConnectionState.waiting){
            return const Center(
              child: CircularProgressIndicator(color: AppColors.purplePrimary),
            );
          }

          if(snapshot.hasError){
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  "Error al cargar periodos: ${snapshot.error}",
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final periods = snapshot.data ?? [];
          if(periods.isEmpty){
           return const _EmptyState(); 
          }

          return ListView.separated( 
            padding: const EdgeInsets.all(20),
            itemCount: periods.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, index) => _PeriodTile(
              period: periods[index],
              formatDate: _formatDate,
              onEdit: () => _openEdit(periods[index]),
              onDelete: () => _confirmDelete(periods[index]),
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.purplePrimary,
        foregroundColor: Colors.white,
        onPressed: _openCreate,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget{
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month,
              color: AppColors.purplePrimary,
              size: 64,
            ),
            SizedBox(height: 16),

            Text(
              "Aún no tienes periodos",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),

            Text(
              "Toca el botón + para crear tu primer periodo académico.",
              style: TextStyle(color: AppColors.hint, fontSize: 14),
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }
}

class _PeriodTile extends StatelessWidget{
  final Period period;
  final String Function(DateTime) formatDate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PeriodTile({
    required this.period,
    required this.formatDate,
    required this.onEdit,
    required this.onDelete
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16)
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  period.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                
                Text(
                  "${formatDate(period.startDate)} - ${formatDate(period.endDate)}",
                  style: const TextStyle(color: AppColors.hint, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit, 
            icon: const Icon(
              Icons.edit_outlined, 
              color: AppColors.purplePrimary
            ),
            tooltip: "Editar",
          ),
          IconButton(
            onPressed: onDelete, 
            icon: const Icon(
              Icons.delete_outline, 
              color: Colors.redAccent
            ),
            tooltip: "Eliminar",
          ),
        ],
      ),
    );
  }
}

