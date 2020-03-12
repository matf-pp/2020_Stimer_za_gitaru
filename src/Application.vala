using Strings;
using Strings.Widgets;

namespace Strings {
    public class Application: Gtk.Application {
        Gtk.ApplicationWindow window;
        Gtk.HeaderBar header;
        Gtk.Button back_button;
        Gtk.MenuButton menu_button;
        Gtk.Stack stack;
        Gtk.AccelGroup accel_group;
        Audio.AudioThread audio_thread;

        const string STACK_TUNER = "tuner";
        const string STACK_PREF_PANE = "pref-pane";

        construct {
            application_id = Strings.Config.APPLICATION_ID;
            flags = GLib.ApplicationFlags.FLAGS_NONE;
        }

        public override void startup () {
            var device = new Audio.Alsa.Device ();
            audio_thread = new Audio.AudioThread.from_device (device);
            base.startup ();
        }

        public override void shutdown () {
            audio_thread.stop ();
            base.shutdown ();
        }

        public override void activate () {
            var settings = Gtk.Settings.get_default ();
            settings.gtk_application_prefer_dark_theme = true;
            var screen = Gdk.Screen.get_default ();
            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("/com/gitlab/dusan-gvozdenovic/strings/stylesheet.css");
            Gtk.StyleContext.add_provider_for_screen (
                screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            Gtk.Settings.get_default ().set ("gtk-application-prefer-dark-theme", true);
            window = new Gtk.ApplicationWindow (this);
            header = new Gtk.HeaderBar ();
            window.set_titlebar (header);
            window.set_default_size (600, 400);
            accel_group = new Gtk.AccelGroup ();
            window.add_accel_group (accel_group);
            build_menu ();
            window.resizable = false;
            // elementaryOS-specific theming
            if (settings.gtk_theme_name == "elementary") {
                var header_style_ctx = header.get_style_context ();
                header_style_ctx.add_class (Gtk.STYLE_CLASS_FLAT);
                header_style_ctx.add_class ("background");
                header_style_ctx.add_class ("default-decoration");
            }
            header.show_close_button = true;
            //  header.pack_start (input_select);
            header.pack_end (menu_button);
            stack = new Gtk.Stack ();
            stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
            stack.get_style_context ().add_class ("container");
            back_button = new Gtk.Button.with_label (_("Back"));
            back_button.get_style_context ().add_class ("back-button");
            back_button.clicked.connect (() => {
                stack.visible_child_name = STACK_TUNER;
                back_button.hide ();
            });
            back_button.valign = Gtk.Align.CENTER;
            header.pack_start (back_button);
            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
            box.homogeneous = false;
            Gauge gauge = new Gauge ();
            gauge.target_value = 330.0;
            gauge.current_value = 230.0;
            audio_thread.tone_recognized.connect (freq => {
                debug ("Frequency: %.2lf", freq);
            });
            ToneSlider slider = new ToneSlider ();
            //  box.pack_start (gauge, true, true, 5);
            box.pack_start (slider, true, false, 5);
            Timeout.add (40, () => {
                gauge.current_value += 1.0;
                gauge.queue_draw ();
                return gauge.current_value != gauge.target_value;
            });
            var pref_pane = new PrefPane ();
            stack.add_named (gauge, STACK_TUNER);
            stack.add_named (pref_pane, STACK_PREF_PANE);
            window.add (stack);
            slider.set_size_request (100, 48);
            window.title = _("Strings");
            window.show_all ();
            back_button.hide ();
        }

        void build_menu () {
            menu_button = new Gtk.MenuButton ();
            menu_button.image = new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.BUTTON);
            var menu = new Gtk.Menu ();
            var pref_item = new Gtk.MenuItem.with_label (_("Preferences"));
            pref_item.add_accelerator(
                "activate", accel_group, ',',
                Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
            pref_item.activate.connect (() => {
                stack.visible_child_name = STACK_PREF_PANE;
                back_button.show_all ();
            });
            var quit_item = new Gtk.MenuItem.with_label (_("Quit"));
            quit_item.activate.connect (this.quit);
            quit_item.add_accelerator(
                "activate", accel_group, 'Q',
                Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
            menu.append (pref_item);
            menu.append (quit_item);
            menu_button.popup = menu;
            menu_button.valign = Gtk.Align.CENTER;
            menu.show_all ();
        }
    }
}

public static int main (string[] args) {
    Intl.setlocale (LocaleCategory.ALL, "");
    Intl.textdomain (Strings.Config.GETTEXT_PACKAGE);
    return new Strings.Application ().run (args);
}
