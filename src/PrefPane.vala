namespace Strings.Widgets {
    public class PrefPane : Gtk.Bin {
        Gtk.ComboBox input_combo;
        Gtk.Box layout;

        construct {
            layout = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
            layout.get_style_context ().add_class ("container");
            //  layout.column_spacing = 3;
            //  layout.margin = 6;
            //  layout.row_spacing = 6;
            //  layout.column_homogeneous = true;
            build_input ();
            add (layout);
        }

        protected enum InputDeviceColumn { NAME, ID }

        void build_input () {
            var hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            var store = new Gtk.ListStore (2, typeof (string), typeof (string));
            Audio.Alsa.DeviceInfo[] infos = Audio.Alsa.get_device_infos ();
            foreach (var info in infos) {
                Gtk.TreeIter iter;
                store.append (out iter);
                var name = "%s - %s".printf (info.card_name, info.device_name);
                store.set (iter, InputDeviceColumn.NAME, name);
                store.set (iter, InputDeviceColumn.ID, info.get_id ());
            }
            input_combo = new Gtk.ComboBox.with_model (store);
            Gtk.CellRendererText cell = new Gtk.CellRendererText ();
            input_combo.pack_start (cell, false);
            input_combo.set_attributes (cell, "text", InputDeviceColumn.NAME);
            input_combo.set_active (0);
            input_combo.changed.connect (input_device_changed);
            hbox.pack_start (new Gtk.Label (_("Devices: ")), false, false);
            hbox.pack_start (input_combo, false, false, 0);
            layout.pack_start (hbox, false, false, 0);
            //  layout.attach (new Gtk.Label (_("Devices: ")), 0, 0, 1);
            //  layout.attach (input_combo, 1, 0, 1);
        }

        void input_device_changed () {
            var model = input_combo.get_model ();
            Value val_id = Value (typeof (string));
            Gtk.TreeIter iter = { };
            input_combo.get_active_iter (out iter);
            model.get_value (iter, InputDeviceColumn.ID, out val_id);
            debug ("You chose %s", val_id.dup_string ());
        }
    }
}