import 'package:flutter/material.dart';
import '../theme/zappr_tokens.dart';
import '../theme/zappr_theme.dart';
import 'live_banner_card.dart';

/// Carousel orizzontale scrollabile per le card "In Onda" con i canali in diretta
class LiveBannerCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> channels;
  final ValueChanged<int>? onPageChanged;
  
  const LiveBannerCarousel({
    super.key,
    required this.channels,
    this.onPageChanged,
  });
  
  @override
  State<LiveBannerCarousel> createState() => _LiveBannerCarouselState();
}

class _LiveBannerCarouselState extends State<LiveBannerCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    widget.onPageChanged?.call(index);
  }
  
  @override
  Widget build(BuildContext context) {
    final scaler = context.scaler;
    
    if (widget.channels.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: [
        // Lista orizzontale scrollabile
        SizedBox(
          height: scaler.s(ZapprTokens.bannerHeight),
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: widget.channels.length,
            itemBuilder: (context, index) {
              final channel = widget.channels[index];
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: scaler.spacing(ZapprTokens.horizontalPadding),
                ),
                child: LiveBannerCard(
                  channelName: channel['name'] as String? ?? '',
                  logoUrl: channel['logo'] as String?,
                  title: 'In Onda',
                  subtitle: '${channel['name']} - Talk Show in Diretta',
                  onTap: () {
                    // Navigate to player
                  },
                ),
              );
            },
          ),
        ),
        // Dots di paginazione
        Padding(
          padding: EdgeInsets.only(
            top: scaler.spacing(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.channels.length, (index) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: scaler.spacing(3)),
                child: GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: scaler.s(6),
                    height: scaler.s(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentIndex
                          ? ZapprTokens.neonBlue
                          : ZapprTokens.textSecondary.withOpacity(0.3),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
