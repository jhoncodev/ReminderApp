import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/utils/time_helpers.dart';
import 'package:reminder_app/models/course_session.dart';

class SessionEditorSheet extends StatefulWidget{
  final CourseSession? initial;
  const SessionEditorSheet({super.key,this.initial});

  static Future<CourseSession?> show(
    BuildContext context,{
      CourseSession? initial,
    }
  ){
    return showModalBottomSheet<CourseSession>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SessionEditorSheet(initial: initial),
    );
  }

  @override
  State<SessionEditorSheet> createState() => _SessionEditorSheetState();
}

class _SessionEditorSheetState extends State<SessionEditorSheet>{
  int? _dayOfWeek;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _errorMessage;
  final _roomController = TextEditingController();

  static const _dayNames = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo'
  ];

  @override
  void initState() {
    super.initState();

    final initial = widget.initial;
    if(initial != null){
      _dayOfWeek = initial.dayOfWeek;
      _startTime = parse24h(initial.startTime);
      _endTime = parse24h(initial.endTime);
      _roomController.text = initial.roomName ?? '';
    }
  }

  @override
  void dispose(){
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _pickDay() async {
    final selected = await showModalBottomSheet<int>(
      context: context, 
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text(
                    'Día de la Semana',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                for(int i = 0; i < _dayNames.length; i++)
                  ListTile(
                    title: Text(
                      _dayNames[i],
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () => Navigator.pop(ctx, i),
                  ),
              ],
            ),
          )
        ),
      ),
    );

    if(selected != null){
      setState(() {
        _dayOfWeek = selected;
        _errorMessage = null;
      });
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context, 
      initialTime: (isStart ? _startTime : _endTime) ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.purplePrimary,
            surface: AppColors.surface,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: AppColors.surface,
          ),
        ), 
        child: child!,
      ),
    );
    
    if(picked == null) return;

    setState(() {
      if(isStart){
        _startTime = picked;
      }else{
        _endTime = picked;
      }
      _errorMessage = null;
    });
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  void _showError(String message){
    setState(() => _errorMessage = message);
  }

  void _save() {
    if(_dayOfWeek == null){
      _showError('Selecciona un día');
      return;
    }

    if(_startTime == null || _endTime == null){
      _showError('Selecciona las horas de inicio y fin');
      return;
    }

    if(_toMinutes(_startTime!) >= _toMinutes(_endTime!)){
      _showError('La hora de fin debe ser mayor a la de inicio');
      return;
    }

    final session = CourseSession(
      dayOfWeek: _dayOfWeek!, 
      startTime: formatTo24h(_startTime!), 
      endTime: formatTo24h(_endTime!),
      roomName: _roomController.text.trim().isEmpty ? null : _roomController.text.trim(),
    );

    Navigator.pop(context, session);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          // El contenido se sube cuando aparece el teclado
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con X para cancelar y check para guardar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context), 
                ),
                IconButton(
                  icon: const Icon(
                    Icons.check,
                    color: AppColors.purplePrimary,
                  ),
                  onPressed: _save, 
                ),
              ],
            ),
            const SizedBox(height: 8),

            if(_errorMessage != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.5),
                    width: 1
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )
            ],

            _buildLabel('DÍA'),
            const SizedBox(height: 8),

            _buildSelectorRow(
              text: _dayOfWeek != null ? _dayNames[_dayOfWeek!] : 'Selecciona',
              onTap: _pickDay,
              hasValue: _dayOfWeek != null,
            ),
            const SizedBox(height: 2,),
            
            _buildLabel('HORA'),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: _buildSelectorRow(
                    text: _startTime != null ? formatTo12h(formatTo24h(_startTime!)) : 'Inicio',
                    onTap: () => _pickTime(isStart: true),
                    hasValue: _startTime != null,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_forward, color: AppColors.hint),
                ),
                Expanded(
                  child: _buildSelectorRow(
                    text: _endTime != null ? formatTo12h(formatTo24h(_endTime!)) : 'Fin',
                    onTap: () => _pickTime(isStart: false),
                    hasValue: _endTime != null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildLabel('AULA (opcional)'),
            const SizedBox(height: 8),

            TextField(
              controller: _roomController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Ej. A-301",
                hintStyle: const TextStyle(color: AppColors.hint),
                filled: true,
                fillColor: AppColors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text){
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.hint,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildSelectorRow({required String text, required VoidCallback onTap, required bool hasValue}){
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  color: hasValue ? Colors.white : AppColors.hint,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.purplePrimary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}