import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/utils/app_feedback.dart';
import 'package:reminder_app/core/widgets/app_label.dart';
import 'package:reminder_app/core/widgets/app_text_field.dart';
import 'package:reminder_app/core/widgets/primary_gradient_button.dart';
import 'package:reminder_app/data/shared_item_repository.dart';
import 'package:reminder_app/data/user_repository.dart';
import 'package:reminder_app/models/course.dart';
import 'package:reminder_app/models/note.dart';
import 'package:reminder_app/models/period.dart';
import 'package:reminder_app/models/reminder.dart';
import 'package:reminder_app/models/teacher.dart';

// Payloads: copia de los datos SIN userId ni ids de vínculos
Map<String, dynamic> reminderPayload(Reminder r) => {
  'name': r.name,
  if (r.notes != null) 'notes': r.notes,
  if (r.budgetAmount != null) 'budgetAmount': r.budgetAmount,
  'frequency': r.frequency,
  'scheduleDays': r.scheduleDays,
  if (r.startTime != null) 'startTime': r.startTime,
  if (r.date != null) 'date': Timestamp.fromDate(r.date!),
};

Map<String, dynamic> coursePayload(Course c) => {
  'name': c.name,
  'sessions': c.sessions.map((s) => s.toMap()).toList(),
  if (c.note != null) 'note': c.note,
  'colorCode': c.colorCode,
  // Sin academicPeriodId: ese periodo no existe en la cuenta del destinatario
};

Map<String, dynamic> notePayload(Note n) => {
  'title': n.title,
  'content': n.content,
  'colorCode': n.colorCode,
  // Sin courseId
};

Map<String, dynamic> periodPayload(Period p) => {
  'name': p.name,
  'startDate': Timestamp.fromDate(p.startDate),
  'endDate': Timestamp.fromDate(p.endDate),
  'isArchived': false,
};

Map<String, dynamic> teacherPayload(Teacher t) => {
  'name': t.name,
  if (t.email != null) 'email': t.email,
  if (t.phone != null) 'phone': t.phone,
};

// Sheet de envío

void showShareSheet(
  BuildContext context, {
  required String type, // 'reminder' | 'course' | 'note' | 'period'
  required String typeLabel, // "Curso", "Apunte", ...
  required String resourceTitle,
  required Map<String, dynamic> payload,
}) {
  final emailController = TextEditingController();
  String? errorMessage;
  bool isSending = false;

  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Compartir $typeLabel',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '"$resourceTitle" se enviará como copia, el destinatario decide si lo acepta.',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 24),
            const AppLabel(text: "Correo del Destinatario"),
            const SizedBox(height: 8),
            AppTextField(
              controller: emailController,
              hint: "compañero@gmail.com",
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ],
            const SizedBox(height: 24),
            PrimaryGradientButton(
              text: isSending ? "Enviando..." : "Enviar",
              glow: true,
              onPressed: isSending
                  ? null
                  : () async {
                      final email = emailController.text.trim().toLowerCase();
                      if (email.isEmpty) {
                        setSheetState(
                          () => errorMessage =
                              "Escribe el correo del destinatario",
                        );
                        return;
                      }
                      final me = FirebaseAuth.instance.currentUser;
                      if (me == null) return;
                      if (email == (me.email ?? '').toLowerCase()) {
                        setSheetState(
                          () =>
                              errorMessage = "No puedes compartirte a ti mismo",
                        );
                        return;
                      }

                      setSheetState(() {
                        isSending = true;
                        errorMessage = null;
                      });

                      try {
                        final repo = SharedItemRepository();
                        final toUserId = await repo.findUserIdByEmail(email);
                        if (toUserId == null) {
                          setSheetState(() {
                            isSending = false;
                            errorMessage =
                                "No existe un usuario con ese correo";
                          });
                          return;
                        }

                        final myProfile = await UserRepository().getCurrentUser(
                          me.uid,
                        );
                        await repo.send(
                          toUserId: toUserId,
                          fromUserName: myProfile?.name ?? 'Alguien',
                          type: type,
                          payload: payload,
                        );

                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                        if (context.mounted) {
                          showSuccessSnack(
                            context,
                            "$typeLabel compartido correctamente",
                          );
                        }
                      } catch (e) {
                        debugPrint("Error al compartir: $e");
                        if (sheetContext.mounted) {
                          setSheetState(() {
                            isSending = false;
                            errorMessage =
                                "No se pudo compartir, revisa tu conexión";
                          });
                        }
                      }
                    },
            ),
          ],
        ),
      ),
    ),
  );
}
