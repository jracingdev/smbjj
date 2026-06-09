import 'package:flutter/material.dart';

import '../core/theme.dart';

import '../models/medalha.dart';

import '../utils/medalha_ranking.dart';



class QuadroMedalhasCard extends StatelessWidget {

  final List<Medalha> medalhas;

  final bool isAdmin;

  final VoidCallback? onGerenciar;



  const QuadroMedalhasCard({

    super.key,

    required this.medalhas,

    this.isAdmin = false,

    this.onGerenciar,

  });



  static const _titulo = 'Quadro de medalhas (Ranking interno)';



  Color _corTipo(String tipo) {

    switch (tipo) {

      case 'ouro':

        return Colors.amber.shade700;

      case 'prata':

        return Colors.blueGrey.shade400;

      case 'bronze':

        return Colors.brown.shade400;

      default:

        return verdeEscuro;

    }

  }



  @override

  Widget build(BuildContext context) {

    final ranking = calcularRankingMedalhas(medalhas);



    return Card(

      child: Padding(

        padding: const EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Row(

              children: [

                const Icon(Icons.emoji_events, color: verdeEscuro),

                const SizedBox(width: 8),

                Expanded(

                  child: Text(_titulo, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),

                ),

                if (isAdmin && onGerenciar != null)

                  TextButton(onPressed: onGerenciar, child: const Text('Gerenciar')),

              ],

            ),

            const SizedBox(height: 4),

            Text(

              'Pontuação: ouro 5 · prata 2 · bronze 1',

              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),

            ),

            const SizedBox(height: 12),

            if (ranking.isEmpty)

              Text('Nenhuma medalha registrada ainda.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13))

            else

              ...ranking.take(10).toList().asMap().entries.map((entry) {

                final pos = entry.key + 1;

                final r = entry.value;

                return Padding(

                  padding: const EdgeInsets.only(bottom: 10),

                  child: Row(

                    children: [

                      CircleAvatar(

                        radius: 14,

                        backgroundColor: pos <= 3 ? Colors.amber.shade100 : Colors.grey.shade200,

                        child: Text(

                          '$pos',

                          style: TextStyle(

                            fontSize: 12,

                            fontWeight: FontWeight.w900,

                            color: pos <= 3 ? Colors.amber.shade900 : Colors.grey.shade700,

                          ),

                        ),

                      ),

                      const SizedBox(width: 10),

                      Expanded(

                        child: Column(

                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [

                            Text(r.alunoNome, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),

                            Text(

                              '${r.pontos} pts · ${r.total} medalha${r.total == 1 ? '' : 's'} · ${r.ouro}O ${r.prata}P ${r.bronze}B',

                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),

                            ),

                          ],

                        ),

                      ),

                      if (r.ouro > 0)

                        Icon(Icons.emoji_events, color: _corTipo('ouro'), size: 18),

                    ],

                  ),

                );

              }),

          ],

        ),

      ),

    );

  }

}


