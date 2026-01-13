import 'package:flutter/material.dart';
import '../theme/zappr_tokens.dart';
import '../theme/zappr_theme.dart';
import 'channel_tile.dart';
import '../features/channels/model/channel.dart';

/// Lista scrollabile di canali in un box contenitore compatto
class ChannelsScrollableList extends StatelessWidget {
  final List<Channel> channels;
  final String? selectedChannelId;
  final Function(Channel) onChannelTap;
  final double? height; // Altezza opzionale per il box
  
  const ChannelsScrollableList({
    super.key,
    required this.channels,
    this.selectedChannelId,
    required this.onChannelTap,
    this.height,
  });
  
  @override
  Widget build(BuildContext context) {
    final scaler = context.scaler;
    
    // Usa l'altezza passata come parametro o un valore di default
    final boxHeight = height ?? scaler.s(280);
    
    if (channels.isEmpty) {
      return Container(
        height: boxHeight,
        margin: EdgeInsets.symmetric(
          horizontal: scaler.spacing(ZapprTokens.horizontalPadding),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(scaler.r(ZapprTokens.r16)),
          color: const Color(0xFF08213C).withOpacity(0.65),
          border: Border.all(
            width: 1.0,
            color: ZapprTokens.neonBlue.withOpacity(0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: ZapprTokens.neonBlue.withOpacity(0.3),
              blurRadius: 15.0 * scaler.scale,
              spreadRadius: 1.0 * scaler.scale,
              offset: Offset(0, 0),
            ),
            BoxShadow(
              color: ZapprTokens.neonCyan.withOpacity(0.2),
              blurRadius: 20.0 * scaler.scale,
              spreadRadius: 0,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icona futuristica con animazione
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 2),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.8 + (value * 0.2),
                    child: Container(
                      padding: EdgeInsets.all(scaler.spacing(16)),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: 2.0,
                          color: ZapprTokens.neonCyan.withOpacity(0.6 * value),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: ZapprTokens.neonCyan.withOpacity(0.4 * value),
                            blurRadius: 20.0 * scaler.scale,
                            spreadRadius: 2.0 * scaler.scale,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.satellite_alt,
                        size: scaler.s(48),
                        color: ZapprTokens.neonCyan.withOpacity(0.9),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: scaler.spacing(16)),
              // Testo con effetto glow
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    ZapprTokens.neonBlue,
                    ZapprTokens.neonCyan,
                    ZapprTokens.neonBlue,
                  ],
                ).createShader(bounds),
                child: Text(
                  'NESSUN CANALE',
                  style: TextStyle(
                    fontSize: scaler.fontSize(ZapprTokens.fontSizePageTitle),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontFamily: ZapprTokens.fontFamily,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              SizedBox(height: scaler.spacing(8)),
              // Sottotesto con animazione
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 1),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: 0.5 + (value * 0.5),
                    child: Text(
                      'In attesa di connessione...',
                      style: TextStyle(
                        fontSize: scaler.fontSize(ZapprTokens.fontSizeSecondary),
                        color: ZapprTokens.neonCyan.withOpacity(0.7),
                        fontFamily: ZapprTokens.fontFamily,
                        letterSpacing: 1.0,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: scaler.spacing(20)),
              // Indicatore di caricamento futuristico
              Container(
                width: scaler.s(200),
                height: scaler.s(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(scaler.r(2)),
                  color: ZapprTokens.neonBlue.withOpacity(0.2),
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeInOut,
                  onEnd: () {
                    // Riavvia l'animazione
                  },
                  builder: (context, value, child) {
                    return Stack(
                      children: [
                        Positioned(
                          left: value * scaler.s(200) - scaler.s(50),
                          child: Container(
                            width: scaler.s(50),
                            height: scaler.s(4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(scaler.r(2)),
                              gradient: LinearGradient(
                                colors: [
                                  ZapprTokens.neonBlue,
                                  ZapprTokens.neonCyan,
                                  ZapprTokens.neonBlue,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: ZapprTokens.neonCyan.withOpacity(0.8),
                                  blurRadius: 8.0,
                                  spreadRadius: 2.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Container(
      height: boxHeight, // Altezza calcolata dinamicamente o default
      margin: EdgeInsets.symmetric(
        horizontal: scaler.spacing(ZapprTokens.horizontalPadding),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(scaler.r(ZapprTokens.r16)),
        // Box container con stesso sfondo del footer
        color: const Color(0xFF08213C).withOpacity(0.65), // Colore personalizzato #08213c con trasparenza 65%
        border: Border.all(
          width: 1.0,
          color: ZapprTokens.neonBlue.withOpacity(0.6), // Stesso bordo del footer
        ),
        // Ombra ridotta (stessa del footer)
        boxShadow: [
          BoxShadow(
            color: ZapprTokens.neonBlue.withOpacity(0.3), // Stessa opacità del footer
            blurRadius: 15.0 * scaler.scale, // Stesso blur del footer
            spreadRadius: 1.0 * scaler.scale, // Stesso spread del footer
            offset: Offset(0, 0),
          ),
          BoxShadow(
            color: ZapprTokens.neonCyan.withOpacity(0.2), // Stessa opacità del footer
            blurRadius: 20.0 * scaler.scale, // Stesso blur del footer
            spreadRadius: 0,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(scaler.r(ZapprTokens.r16)),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(), // Sempre abilita lo scroll verticale
          scrollDirection: Axis.vertical, // Scroll verticale esplicito
          shrinkWrap: false, // Importante: non usare shrinkWrap
          padding: EdgeInsets.symmetric(
            vertical: scaler.spacing(8),
            horizontal: scaler.spacing(4),
          ),
          itemCount: channels.length,
          itemBuilder: (context, index) {
            final channel = channels[index];
            final isSelected = selectedChannelId == channel.id;
            
            // Log per debug canali per bambini
            if (channel.category?.toLowerCase() == 'bambini' && index < 5) {
              // ignore: avoid_print
              print('ChannelsScrollableList: 📺 Rendering canale per bambini #${index + 1}: "${channel.name}"');
            }
            
            return ChannelTile(
              channelName: channel.name,
              logoUrl: channel.logo,
              channelId: channel.id,
              isSelected: isSelected,
              onTap: () => onChannelTap(channel),
            );
          },
        ),
      ),
    );
  }
}
