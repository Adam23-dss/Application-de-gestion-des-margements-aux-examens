import 'package:flutter/material.dart';
import 'package:frontend1/core/themes/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;
  final VoidCallback? onBackPressed;
  final bool showDivider;
  
  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.centerTitle = true,
    this.bottom,
    this.onBackPressed,
    this.showDivider = true,
  });
  
  @override
  Size get preferredSize {
    final height = kToolbarHeight;
    if (bottom != null) {
      return Size.fromHeight(height + bottom!.preferredSize.height);
    }
    return Size.fromHeight(height);
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppBar(
      backgroundColor: backgroundColor ?? Colors.white,
      foregroundColor: foregroundColor ?? AppColors.primary,
      elevation: elevation,
      shadowColor: elevation > 0 ? AppColors.textSecondary : Colors.transparent,
      centerTitle: centerTitle,
      titleSpacing: showBackButton ? 0 : 16,
      
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: foregroundColor ?? AppColors.primary,
          letterSpacing: 0.15,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      
      leading: showBackButton
          ? (leading ?? _buildBackButton(context))
          : null,
      
      leadingWidth: showBackButton ? 56 : null,
      
      actions: actions != null
          ? [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: actions!,
                ),
              ),
            ]
          : null,
      
      bottom: bottom,
      
      shape: showDivider
          ? const Border(
              bottom: BorderSide(
                color: Color.fromRGBO(0, 0, 0, 0.08),
                width: 1,
              ),
            )
          : null,
      
      flexibleSpace: _buildFlexibleSpace(),
    );
  }
  
  Widget _buildBackButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
      iconSize: 20,
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(),
      onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    );
  }
  
  Widget _buildFlexibleSpace() {
    return Container(
      decoration: BoxDecoration(
        gradient: backgroundColor == null
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.95),
                  Colors.white,
                ],
              )
            : null,
      ),
    );
  }
}

// Variantes de CustomAppBar
class CustomSliverAppBar extends StatelessWidget {
  final String title;
  final bool pinned;
  final bool floating;
  final bool snap;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;
  final double expandedHeight;
  final Widget? flexibleSpace;
  final PreferredSizeWidget? bottom;
  
  const CustomSliverAppBar({
    super.key,
    required this.title,
    this.pinned = true,
    this.floating = false,
    this.snap = false,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.expandedHeight = 120,
    this.flexibleSpace,
    this.bottom,
  });
  
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
      leading: leading,
      actions: actions,
      backgroundColor: backgroundColor ?? Colors.white,
      elevation: 0,
      pinned: pinned,
      floating: floating,
      snap: snap,
      expandedHeight: expandedHeight,
      flexibleSpace: flexibleSpace ?? _buildDefaultFlexibleSpace(),
      bottom: bottom,
      shape: const Border(
        bottom: BorderSide(
          color: Color.fromRGBO(0, 0, 0, 0.08),
          width: 1,
        ),
      ),
    );
  }
  
  Widget _buildDefaultFlexibleSpace() {
    return FlexibleSpaceBar(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      centerTitle: true,
      background: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.8),
              AppColors.primary.withOpacity(0.4),
            ],
          ),
        ),
      ),
    );
  }
}

// AppBar avec search
class SearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String hintText;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchSubmitted;
  final VoidCallback? onCancel;
  final bool showCancelButton;
  final Widget? leading;
  final List<Widget>? actions;
  
  const SearchAppBar({
    super.key,
    this.hintText = 'Rechercher...',
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.onCancel,
    this.showCancelButton = true,
    this.leading,
    this.actions,
  });
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  
  @override
  State<SearchAppBar> createState() => _SearchAppBarState();
}

class _SearchAppBarState extends State<SearchAppBar> {
  final TextEditingController _controller = TextEditingController();
  bool _isSearching = false;
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _onSearchChanged(String value) {
    setState(() {
      _isSearching = value.isNotEmpty;
    });
    widget.onSearchChanged?.call(value);
  }
  
  void _onClearPressed() {
    _controller.clear();
    _onSearchChanged('');
  }
  
  void _onCancelPressed() {
    _controller.clear();
    _onSearchChanged('');
    widget.onCancel?.call();
  }
  
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: widget.leading,
      title: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: widget.hintText,
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: _onClearPressed,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        onChanged: _onSearchChanged,
        onSubmitted: (value) => widget.onSearchSubmitted?.call(),
        autofocus: true,
        style: const TextStyle(fontSize: 16),
      ),
      actions: [
        if (widget.showCancelButton)
          TextButton(
            onPressed: _onCancelPressed,
            child: const Text(
              'Annuler',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ...?widget.actions,
      ],
      shape: const Border(
        bottom: BorderSide(
          color: Color.fromRGBO(0, 0, 0, 0.08),
          width: 1,
        ),
      ),
    );
  }
}

// AppBar avec tabs
class TabbedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final TabController tabController;
  final List<Widget> tabs;
  final List<Widget>? actions;
  final bool showBackButton;
  final Color? backgroundColor;
  
  const TabbedAppBar({
    super.key,
    required this.title,
    required this.tabController,
    required this.tabs,
    this.actions,
    this.showBackButton = true,
    this.backgroundColor,
  });
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight * 2);
  
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? Colors.white,
      foregroundColor: AppColors.primary,
      elevation: 1,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      actions: actions,
      bottom: TabBar(
        controller: tabController,
        tabs: tabs,
        labelColor: AppColors.primary,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        isScrollable: tabs.length > 3,
      ),
      shape: const Border(
        bottom: BorderSide(
          color: Color.fromRGBO(0, 0, 0, 0.08),
          width: 1,
        ),
      ),
    );
  }
}