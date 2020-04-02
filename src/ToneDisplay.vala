using Strings;
using Strings.Audio.Tuning;

namespace Strings.Widgets {
    public class ToneDisplay : Gtk.Box {

        protected Gtk.Label tone_label;
        protected Gtk.Label hidden_tone_label;
        protected Gtk.Label freq_label;
        protected Gtk.ToggleButton lock_btn;
        protected Gtk.Revealer left_rvl;
        protected Gtk.Revealer right_rvl;
        protected Gtk.Stack tone_slider;
        protected Gtk.Button left_btn;
        protected Gtk.Button right_btn;

        protected double freq = 440.00;
        public double frequency {
            get { return freq; }
            set { freq_label.label = frequency_format (freq = value); }
        }

        private string frequency_format (double frequency) { return "%.2lf Hz".printf (frequency); }

        protected uint _target_tone_index;
        public uint target_tone_index {
            get { return _target_tone_index; }
            set {
                assert (value >= 0 && value <= Config.instance.scale.length);
                if (_target_tone_index == value) { return; }
                Gtk.StackTransitionType transition = Gtk.StackTransitionType.NONE;
                if (!Config.instance.automatic_tuning) {
                    transition = _target_tone_index < value ?
                        Gtk.StackTransitionType.SLIDE_LEFT :
                        Gtk.StackTransitionType.SLIDE_RIGHT;
                }
                ToneInfo info = { };
                Config.instance.scale.tone_info (value, ref info);
                set_tone (ref info, transition);
                _target_tone_index = value;
            }
        }

        protected const string ICON_LOCKED = "changes-prevent-symbolic";
        protected const string ICON_UNLOCKED = "changes-allow-symbolic";
        protected const string ICON_LEFT = "pan-start-symbolic";
        protected const string ICON_RIGHT = "pan-end-symbolic";

        construct {
            orientation = Gtk.Orientation.VERTICAL;
            left_rvl = new Gtk.Revealer ();
            right_rvl = new Gtk.Revealer ();
            left_rvl.transition_type =
                right_rvl.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
            left_rvl.transition_duration = right_rvl.transition_duration = 500;
            left_btn = new Gtk.Button.from_icon_name (ICON_LEFT, Gtk.IconSize.BUTTON);
            left_btn.clicked.connect (() => previous_tone ());
            right_btn = new Gtk.Button.from_icon_name (ICON_RIGHT, Gtk.IconSize.BUTTON);
            right_btn.clicked.connect (() => next_tone ());
            left_btn.get_style_context ().add_class ("tone-display-nav-btn");
            right_btn.get_style_context ().add_class ("tone-display-nav-btn");
            left_btn.relief = Gtk.ReliefStyle.NONE;
            right_btn.relief = Gtk.ReliefStyle.NONE;
            var dummy_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            dummy_box.pack_start (create_dummy_label ());
            dummy_box.pack_start (left_btn, false);
            dummy_box.pack_start (create_dummy_label ());
            left_rvl.add (dummy_box);
            dummy_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            dummy_box.pack_start (create_dummy_label ());
            dummy_box.pack_start (right_btn, false);
            dummy_box.pack_start (create_dummy_label ());
            right_rvl.add (dummy_box);
            var hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            build_tone_slider ();
            hbox.pack_start (left_rvl, false, false);
            hbox.pack_start (tone_slider);
            hbox.pack_start (right_rvl, false, false);
            freq_label = new Gtk.Label (frequency_format (frequency));
            freq_label.get_style_context ().add_class ("freq-text");
            lock_btn = new Gtk.ToggleButton ();
            lock_btn.relief = Gtk.ReliefStyle.NONE;
            lock_btn.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            lock_btn.clicked.connect (lock_clicked);
            pack_start (create_dummy_label ());
            pack_start (hbox, false);
            pack_start (freq_label, false);
            var lock_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            lock_box.pack_start (create_dummy_label ());
            lock_box.pack_start (lock_btn, false);
            lock_box.pack_start (create_dummy_label ());
            pack_start (create_dummy_label ());
            pack_start (lock_box, false, false);
            lock_ui (Config.instance.automatic_tuning);
        }

        private void build_tone_slider () {
            _target_tone_index = Config.instance.scale.closest_tone_index (frequency);
            ToneInfo info = { };
            Config.instance.scale.tone_info (_target_tone_index, ref info);
            tone_slider = new Gtk.Stack ();
            tone_label = new Gtk.Label (info.to_pango_markup ());
            tone_label.get_style_context ().add_class ("tone-name");
            tone_label.use_markup = true;
            hidden_tone_label = new Gtk.Label ("");
            hidden_tone_label.get_style_context ().add_class ("tone-name");
            hidden_tone_label.use_markup = true;
            tone_slider.add (tone_label);
            tone_slider.add (hidden_tone_label);
            tone_slider.add_events (Gdk.EventMask.SCROLL_MASK);
            tone_slider.scroll_event.connect (slider_scroll);
        }

        protected bool slider_scroll (Gtk.Widget sender, Gdk.EventScroll event) {
            if (Config.instance.automatic_tuning) { return true; }
            switch (event.direction) {
                case Gdk.ScrollDirection.DOWN:
                case Gdk.ScrollDirection.RIGHT:
                    next_tone ();
                    break;
                case Gdk.ScrollDirection.UP:
                case Gdk.ScrollDirection.LEFT:
                    previous_tone ();
                    break;
            }
            return true;
        }

        private Gtk.Label create_dummy_label () {
            var dummy = new Gtk.Label ("");
            dummy.get_style_context ().add_class ("empty-label");
            return dummy;
        }

        private void lock_clicked () {
            Config.instance.automatic_tuning = !Config.instance.automatic_tuning;
            lock_ui (Config.instance.automatic_tuning);
        }

        protected void lock_ui (bool locked) {
            left_rvl.reveal_child = right_rvl.reveal_child = !locked;
            var icon_name = locked ? ICON_LOCKED : ICON_UNLOCKED;
            lock_btn.image = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.BUTTON);
        }

        protected void set_tone (ref ToneInfo info, Gtk.StackTransitionType transition_type) {
            hidden_tone_label.label = info.to_pango_markup ();
            tone_slider.transition_type = transition_type;
            tone_slider.set_visible_child (hidden_tone_label);
            var tmp = hidden_tone_label;
            hidden_tone_label = tone_label;
            tone_label = tmp;
        }

        protected void next_tone () {
            var scale = Config.instance.scale;
            if (target_tone_index >= scale.length - 1) { return; }
            target_tone_index = scale.next_tone_index (target_tone_index);
        }

        protected void previous_tone () {
            var scale = Config.instance.scale;
            if (target_tone_index <= 0) { return; }
            target_tone_index = scale.previous_tone_index (target_tone_index);
        }
    }
}