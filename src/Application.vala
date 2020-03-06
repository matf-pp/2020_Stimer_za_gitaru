using Strings;
using Strings.Widgets;

namespace Strings {
    public class Application: Gtk.Application {
        Gtk.ApplicationWindow window;
        Gtk.HeaderBar header;
        Gtk.Button input_select;
        Gtk.Button test_record;
        string selected_dev_id;
        Audio.Device device;

        construct {
            application_id = Strings.Config.APPLICATION_ID;
            flags = GLib.ApplicationFlags.FLAGS_NONE;
        }

        public override void activate () {
            device = new Audio.Alsa.Device ();
            var settings = Gtk.Settings.get_default ();
            settings.gtk_application_prefer_dark_theme = true;
            var screen = Gdk.Screen.get_default ();
            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("/com/gitlab/dusan-gvozdenovic/strings/stylesheet.css");
            Gtk.StyleContext.add_provider_for_screen (
                screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            window = new Gtk.ApplicationWindow (this);
            header = new Gtk.HeaderBar ();
            var menu = new Gtk.Button.from_icon_name ("open-menu-symbolic");
            window.set_titlebar (header);
            window.set_default_size (600, 400);
            // window.resizable = false;
            // elementaryOS-specific theming
            if (settings.gtk_theme_name == "elementary") {
                var header_style_ctx = header.get_style_context ();
                header_style_ctx.add_class (Gtk.STYLE_CLASS_FLAT);
                header_style_ctx.add_class ("background");
                header_style_ctx.add_class ("default-decoration");
            }
            header.show_close_button = true;
            build_input ();
            header.pack_start (input_select);
            Gtk.Settings.get_default ().set ("gtk-application-prefer-dark-theme", true);
            test_record = new Gtk.Button.from_icon_name ("face-monkey");
            test_record.clicked.connect (test_record_clicked);
            header.pack_end (menu);
            header.pack_end (test_record);
            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
            box.homogeneous = false;
            Gauge gauge = new Gauge ();
            gauge.target_value = 330.0;
            gauge.current_value = 230.0;
            ToneSlider slider = new ToneSlider ();
            //  box.pack_start (gauge, true, true, 5);
            box.pack_start (slider, true, false, 5);
            GLib.Timeout.add (40, () => {
                gauge.current_value += 1.0;
                gauge.queue_draw ();
                return gauge.current_value != gauge.target_value;
            });
            //  window.add (box);
            window.add (gauge);
            slider.set_size_request (100, 48);
            window.title = _("Strings");
            window.show_all ();
        }

        void build_input () {
            input_select = new Gtk.Button.from_icon_name ("microphone-sensitivity-medium-symbolic");
            var popover = new Gtk.Popover (input_select);
            popover.modal = true;
            var vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
            var names = Audio.Alsa.get_device_names ();
            selected_dev_id = names[0];
            var i_rb = new Gtk.RadioButton.with_label (null, names[0]);
            vbox.pack_start (i_rb, true, false);
            for (var i = 1; i < names.length; i++) {
                var rb = new Gtk.RadioButton.with_label_from_widget (i_rb, names[i]);
                vbox.pack_start (rb, true, false);
            }
            popover.add (vbox);
            input_select.clicked.connect (popover.show_all);
        }

        void test_record_clicked () {
            Posix.printf ("Recording started!\n");
            var signal = new Audio.Sample[3 * device.sample_rate];
            try {
                device.init ();
                device.record (signal);
            } catch (Audio.DeviceError devErr) {
                stderr.printf ("%s\n", devErr.message);
            } finally {
                device.close ();
            }
            Posix.printf ("Recording finished!\n");
            var file = Posix.FILE.open ("test.txt", "w");
            foreach (var sample in signal) {
                file.printf("%d ", sample);
            }
        }
    }
}

public static int main (string[] args) {
    Intl.setlocale (LocaleCategory.ALL, "");
    Intl.textdomain (Strings.Config.GETTEXT_PACKAGE);
    return new Strings.Application ().run (args);
}
