using CopilotKeyRemapper.Classes.Settings;
using CopilotKeyRemapper.Services;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace CopilotKeyRemapper.Pages;

public sealed partial class HomePage : Page
{
    public HomePage()
    {
        InitializeComponent();
        ActionText.Text = ActionSummary.Describe(SettingsManager.Current.Action);
        RefreshStatus();
    }

    private void RefreshStatus()
    {
        if (!CopilotKeyProvider.IsPackaged)
        {
            StatusBar.Severity = InfoBarSeverity.Informational;
            StatusBar.Title = "Not installed as a packaged app";
            StatusBar.Message = "The Copilot key can only be assigned to a signed, installed (MSIX) build. This unpackaged build is for development.";
            AssignButton.Visibility = Visibility.Collapsed;
            return;
        }

        switch (CopilotKeyProvider.GetStatus())
        {
            case ProviderStatus.Assigned:
            case ProviderStatus.AssignedByPolicy:
                StatusBar.Severity = InfoBarSeverity.Success;
                StatusBar.Title = "Assigned";
                StatusBar.Message = "Copilot Key Remapper is set as your Copilot key. Press the key to run your action.";
                AssignButton.Content = "Change in Windows Settings";
                break;
            case ProviderStatus.AssignedToOtherApp:
                StatusBar.Severity = InfoBarSeverity.Warning;
                StatusBar.Title = "The Copilot key is assigned to a different app";
                StatusBar.Message = "Open Windows Settings and choose Copilot Key Remapper to use the action below.";
                break;
            case ProviderStatus.SetToSearch:
                StatusBar.Severity = InfoBarSeverity.Warning;
                StatusBar.Title = "The Copilot key opens Search";
                StatusBar.Message = "Open Windows Settings and choose Copilot Key Remapper to use the action below.";
                break;
            default:
                StatusBar.Severity = InfoBarSeverity.Warning;
                StatusBar.Title = "Not assigned yet";
                StatusBar.Message = "Open Windows Settings → Customize Copilot key, choose \"Custom\", and pick Copilot Key Remapper.";
                break;
        }
    }

    private void AssignButton_Click(object sender, RoutedEventArgs e)
        => CopilotKeyProvider.OpenAssignmentSettings();

    private void ChangeButton_Click(object sender, RoutedEventArgs e)
        => SettingsWindow.GetCurrent()?.NavigateTo(typeof(ActionPage));

    private void TestButton_Click(object sender, RoutedEventArgs e)
        => ActionExecutor.Run(SettingsManager.Current.Action);
}
