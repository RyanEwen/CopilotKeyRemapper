using CopilotKeyRemapper.Classes;
using CopilotKeyRemapper.Classes.Settings;
using Microsoft.UI.Xaml.Controls;

namespace CopilotKeyRemapper.Pages;

public sealed partial class SettingsPage : Page
{
    private bool _loaded;

    public SettingsPage()
    {
        InitializeComponent();
        ThemeCombo.SelectedIndex = SettingsManager.Current.AppTheme;
        _loaded = true;
    }

    private void ThemeCombo_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (!_loaded) return;
        ThemeManager.ApplyAndSaveTheme(ThemeCombo.SelectedIndex);
    }
}
