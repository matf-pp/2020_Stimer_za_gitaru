namespace Strings.Widgets {
    public class Gauge: Gtk.DrawingArea {
        public uint padding_width { get; set; }
        public uint padding_height { get; set; }


        public override bool draw (Cairo.Context cr) {
            Gtk.Allocation allocation;
            get_allocation (out allocation);
            var width = allocation.width - 2 * padding_width;
            var height = allocation.height - 2 * padding_height;
            var min_size = width <= height ? width : height;
            var center_x = padding_width + width / 2;
            var center_y = padding_height + (3.0 / 5) * height;
            var radius = min_size / 2;
            // Draw outermost arc
            cr.set_source_rgba (0.012, 0.063, 0.286, 0.75);
            cr.set_line_width (30.0);
            cr.arc (center_x, center_y, radius, -Math.PI / 4 + Math.PI, 5 * Math.PI / 4 + Math.PI);
            cr.stroke ();
            // Draw inner arc
            cr.set_line_width (20.0);
            cr.set_source_rgba (0.008, 0.071, 0.204, 0.25);
            cr.arc (center_x, center_y, radius - 25.0, -Math.PI / 4 + Math.PI, 5 * Math.PI / 4 + Math.PI);
            cr.stroke ();
            //  cr.set_line_width (1);
            //  cr.set_source_rgba (255, 255, 0, 1);
            //  cr.save ();
            //  cr.scale (allocation.width, allocation.height);
            //  cr.move_to (0, 0);
            //  cr.line_to (1, 1);
            //  cr.restore ();
            //  cr.stroke ();
            //  cr.select_font_face ("DejaVu Sans Mono", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
            //  cr.set_font_size (18);
            //  string message = _("Hello, World :)");
            //  Cairo.TextExtents extents;
            //  cr.text_extents (message, out extents);
            //  double x = allocation.width / 2 - extents.width / 2 - extents.x_bearing;
            //  double y = allocation.height / 2 - extents.height / 2 - extents.y_bearing;
            //  cr.move_to (x, y);
            //  cr.show_text (message);
            return false;
        }
    }
}