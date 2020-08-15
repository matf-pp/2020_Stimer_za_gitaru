/*
 * Copyright (C) 2020 Dušan Gvozdenović. All rights reserved.
 *
 * This file is part of Strings.
 *
 * Strings is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Strings is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Strings. If not, see <https://www.gnu.org/licenses/>.
 */

using Strings;
using Strings.Audio;
using Strings.Widgets;

namespace Strings {
    public class Application: Gtk.Application {
        Gtk.ApplicationWindow window;
        Gtk.HeaderBar header;
        Gtk.Button back_button;
        Gtk.MenuButton menu_button;
        Gtk.Stack stack;
        Gtk.AccelGroup accel_group;
        AudioThread audio_thread;
        Gauge gauge;
        ToneDisplay display;

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
            provider.load_from_resource ("/io/gvozdenovic/strings/stylesheet.css");
            Gtk.StyleContext.add_provider_for_screen (
                screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
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
            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            box.homogeneous = false;
            gauge = new Gauge ();
            display = new ToneDisplay ();
            gauge.add (display);
            audio_thread.tone_recognized.connect (tone_recognized);
            box.pack_start (gauge, true, true);
            stack.add_named (box, STACK_TUNER);
            stack.add_named (new PrefPane (), STACK_PREF_PANE);
            window.add (stack);
            display.set_size_request (10, 48);
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

        void tone_recognized (double frequency) {
            var config = Config.instance;
            var idx = config.automatic_tuning ?
                config.tuning_standard.closest_tone_index (frequency) :
                display.target_tone_index;
            update_gauge (idx, frequency);
            display.frequency = frequency;
            gauge.queue_draw ();
            debug ("Frequency: %.2lf Hz", frequency);
        }

        void update_gauge (uint ref_idx, double frequency) {
            var std = Config.instance.tuning_standard;
            Tuning.ToneInfo info = { };
            Tuning.ToneInfo next_info = { };
            Tuning.ToneInfo previous_info = { };
            var prev_idx = std.previous_tone_index (ref_idx);
            var next_idx = std.next_tone_index (ref_idx);
            std.tone_info (ref_idx, ref info);
            std.tone_info (prev_idx, ref previous_info);
            std.tone_info (next_idx, ref next_info);
            var from_freq = previous_info.frequency;
            var to_freq = next_info.frequency;
            debug ("Frequency: %lf", frequency);
            debug ("Target frequency: %lf", info.frequency);
            debug ("From frequency: %lf", from_freq);
            debug ("To frequency: %lf", to_freq);
            var diff = 0.0;
            if (frequency > info.frequency) {
                diff = (frequency - info.frequency) / (to_freq - info.frequency) * 50.0;
            } else {
                diff = (frequency - info.frequency) / (info.frequency - from_freq) * 50.0;
            }
            debug ("Diff: %lf", diff);
            gauge.current_value = diff;
            display.target_tone_index = ref_idx;
        }
    }
}

public static int main (string[] args) {
    Intl.setlocale (LocaleCategory.ALL, "");
    Intl.textdomain (Strings.Config.GETTEXT_PACKAGE);
    return new Strings.Application ().run (args);
}
