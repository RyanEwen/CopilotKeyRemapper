using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media.Imaging;
using System.IO;

namespace CopilotKeyRemapper.Pages;

public sealed partial class AboutPage : Page
{
    public AboutPage()
    {
        InitializeComponent();

        var asm = typeof(AboutPage).Assembly.GetName();
        var v = asm.Version!;
        VersionText.Text = $"Version {v.Major}.{v.Minor}.{v.Build}";

        try
        {
            string ico = App.IconPath;
            if (File.Exists(ico))
                AppIcon.Source = new BitmapImage(new Uri(ico));
        }
        catch { /* ignore */ }
    }
}
