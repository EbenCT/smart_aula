import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ThemeToggleButton extends StatelessWidget {
  final bool showLabel;
  final double? iconSize;
  
  const ThemeToggleButton({
    Key? key,
    this.showLabel = false,
    this.iconSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        if (showLabel) {
          return TextButton.icon(
            onPressed: () => _showThemeDialog(context, themeProvider),
            icon: Icon(
              themeProvider.themeIcon,
              size: iconSize ?? 24,
            ),
            label: Text(themeProvider.themeText),
          );
        } else {
          return IconButton(
            onPressed: () => _showThemeDialog(context, themeProvider),
            icon: Icon(
              themeProvider.themeIcon,
              size: iconSize ?? 24,
            ),
            tooltip: 'Cambiar tema',
          );
        }
      },
    );
  }

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar tema'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildThemeOption(
                context,
                themeProvider,
                'Modo Claro',
                Icons.light_mode,
                ThemeMode.light,
                themeProvider.isLightMode,
              ),
              _buildThemeOption(
                context,
                themeProvider,
                'Modo Oscuro',
                Icons.dark_mode,
                ThemeMode.dark,
                themeProvider.isDarkMode,
              ),
              _buildThemeOption(
                context,
                themeProvider,
                'Tema del Sistema',
                Icons.brightness_auto,
                ThemeMode.system,
                themeProvider.isSystemMode,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('CERRAR'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeProvider themeProvider,
    String title,
    IconData icon,
    ThemeMode mode,
    bool isSelected,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).primaryColor : null,
      ),
      title: Text(title),
      trailing: isSelected 
          ? Icon(Icons.check, color: Theme.of(context).primaryColor)
          : null,
      onTap: () async {
        switch (mode) {
          case ThemeMode.light:
            await themeProvider.setLightMode();
            break;
          case ThemeMode.dark:
            await themeProvider.setDarkMode();
            break;
          case ThemeMode.system:
            await themeProvider.setSystemMode();
            break;
        }
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
    );
  }
}

// Widget para cambio rápido entre claro y oscuro
class QuickThemeToggle extends StatelessWidget {
  const QuickThemeToggle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return IconButton(
          onPressed: () async {
            await themeProvider.toggleTheme();
            
            // Mostrar snackbar con el tema actual
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cambiado a ${themeProvider.themeText}'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              themeProvider.themeIcon,
              key: ValueKey(themeProvider.themeMode),
            ),
          ),
          tooltip: 'Alternar tema (${themeProvider.themeText})',
        );
      },
    );
  }
}