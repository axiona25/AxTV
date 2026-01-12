import 'package:flutter/material.dart';
import '../theme/zappr_tokens.dart';
import '../theme/zappr_theme.dart';
import 'neon_glass.dart';

/// Widget per mostrare la programmazione del canale
/// Mostra orari, titoli e immagini dei programmi
class ChannelSchedule extends StatelessWidget {
  final String channelId;
  final String channelName;

  const ChannelSchedule({
    super.key,
    required this.channelId,
    required this.channelName,
  });

  @override
  Widget build(BuildContext context) {
    final scaler = context.scaler;
    
    // TODO: Caricare dati programmazione da API/JSON
    // Per ora mostra placeholder
    return Container(
      padding: EdgeInsets.all(scaler.spacing(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titolo sezione
          Text(
            'Programmazione',
            style: TextStyle(
              fontSize: scaler.fontSize(20),
              fontWeight: FontWeight.bold,
              color: ZapprTokens.textPrimary,
            ),
          ),
          SizedBox(height: scaler.spacing(16)),
          // Placeholder per programmazione
          NeonGlass(
            radius: ZapprTokens.r16,
            fill: const Color(0xFF08213C).withOpacity(0.65),
            padding: EdgeInsets.all(scaler.spacing(16)),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.schedule,
                    size: scaler.s(48),
                    color: ZapprTokens.neonCyan.withOpacity(0.5),
                  ),
                  SizedBox(height: scaler.spacing(12)),
                  Text(
                    'Programmazione in caricamento...',
                    style: TextStyle(
                      fontSize: scaler.fontSize(14),
                      color: ZapprTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modello per un programma nella programmazione
class ProgramItem {
  final String time;
  final String title;
  final String? imageUrl;
  final String? description;

  const ProgramItem({
    required this.time,
    required this.title,
    this.imageUrl,
    this.description,
  });
}
