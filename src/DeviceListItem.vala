using Strings.Audio.Alsa;

namespace Strings.Widgets {
    public class DeviceListItem : Gtk.Bin {
        protected Gtk.Box layout;

        public DeviceInfo info { get; set; }

        public DeviceListItem (DeviceInfo info) {
            get_style_context ().add_class ("list-item");
            this.info = info;
            layout = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
            var icon = new Gtk.Image.from_icon_name ("microphone-sensitivity-high-symbolic", Gtk.IconSize.MENU);
            icon.get_style_context ().add_class ("icon");
            var checkmark = new Gtk.Image.from_icon_name ("object-select-symbolic", Gtk.IconSize.MENU);
            checkmark.get_style_context ().add_class ("checkmark");
            var name = "%s - %s".printf (info.card_name, info.device_name);
            layout.pack_start (icon, true, false);
            layout.pack_start (new Gtk.Label (name), false, false);
            //  layout.pack_start (new Gtk.Separator (Gtk.Orientation.VERTICAL), false, false);
            layout.pack_start (checkmark, false, false);
            add (layout);
        }
    }
}