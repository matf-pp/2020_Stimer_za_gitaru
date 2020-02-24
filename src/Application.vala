using Strings.Widgets;

namespace Strings {
    public class Application: Gtk.Application {
        construct {
            application_id = Strings.Config.APPLICATION_ID;
            flags = GLib.ApplicationFlags.FLAGS_NONE;
        }

        public override void activate () {
            Gtk.Settings.get_default ().set ("gtk-application-prefer-dark-theme", true);
            var screen = Gdk.Screen.get_default ();
            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("/com/gitlab/dusan-gvozdenovic/strings/stylesheet.css");
            Gtk.StyleContext.add_provider_for_screen (screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            var window = new Gtk.ApplicationWindow (this);
            var header = new Gtk.HeaderBar ();
            var input = new Gtk.Button.from_icon_name ("microphone-sensitivity-medium-symbolic", Gtk.IconSize.BUTTON);
            window.set_titlebar (header);
            window.set_default_size (600, 400);
            window.resizable = false;
            header.show_close_button = true;
            header.pack_start (input);
            Gauge gauge = new Gauge ();
            window.add (gauge);
            window.title = _("Strings");
            window.show_all ();
        }
    }
}

public static int main (string[] args) {
    Intl.setlocale (LocaleCategory.ALL, "");
    Intl.textdomain (Strings.Config.GETTEXT_PACKAGE);
    return new Strings.Application ().run (args);
}