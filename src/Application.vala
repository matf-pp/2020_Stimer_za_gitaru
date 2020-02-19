using Strings.Widgets;

namespace Strings {
    public class Application: Gtk.Application {
        construct {
            application_id = Strings.Config.APPLICATION_ID;
            flags = GLib.ApplicationFlags.FLAGS_NONE;
        }

        public override void activate () {
            var window = new Gtk.ApplicationWindow (this);
            var header = new Gtk.HeaderBar ();
            var input = new Gtk.Button.from_icon_name ("audio-input-microphone", Gtk.IconSize.BUTTON);
            window.set_titlebar (header);
            window.set_default_size (600, 400);
            window.resizable = false;
            header.show_close_button = true;
            header.pack_start (input);
            Gtk.Settings.get_default ().set ("gtk-application-prefer-dark-theme", true);
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