import 'package:flutter/material.dart';
import '../utils/bjj_utils.dart';
import '../utils/date_utils.dart';

/// Seletor de mês e ano — exibição MM-YYYY (armazenamento YYYY-MM).
class MesAnoPicker extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final String label;
  final bool opcional;

  const MesAnoPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Início nas aulas',
    this.opcional = true,
  });

  @override
  Widget build(BuildContext context) {
    final parsed = parseMesAno(value);
    final mes = parsed?.$1;
    final ano = parsed?.$2 ?? DateTime.now().year;
    final anos = List.generate(30, (i) => DateTime.now().year - i);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        if (opcional)
          Text('Opcional — $hintMesAno', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<int?>(
                value: mes,
                decoration: const InputDecoration(labelText: 'Mês', isDense: true),
                items: [
                  if (opcional) const DropdownMenuItem<int?>(value: null, child: Text('—')),
                  ...List.generate(12, (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text(meses[i]),
                      )),
                ],
                onChanged: (m) {
                  if (m == null) {
                    onChanged(null);
                  } else {
                    onChanged(mesAnoParaIso(m, ano));
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<int>(
                value: ano,
                decoration: const InputDecoration(labelText: 'Ano', isDense: true),
                items: anos
                    .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                    .toList(),
                onChanged: mes == null
                    ? null
                    : (y) {
                        if (y != null) onChanged(mesAnoParaIso(mes, y));
                      },
              ),
            ),
          ],
        ),
        if (value != null && value!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              formatMesAnoBr(value),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
      ],
    );
  }
}
