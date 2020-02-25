namespace Strings.Widgets {
    public class Gauge: Gtk.DrawingArea {
        public uint padding_width { get; set; }
        public uint padding_height { get; set; }

        public double angle_from { get; set; }
        public double angle_to { get; set; }
        public double outer_arc_width { get; set; }
        public double inner_arc_width { get; set; }
        public double inner_circle_margin { get; set; }

        public string text { get; set; }

        construct {
            padding_width = 5;
            padding_height = 5;
            angle_from = -Math.PI / 4 + Math.PI;
            angle_to = 5 * Math.PI / 4 + Math.PI;
            outer_arc_width = 40.0;
            inner_arc_width = 20.0;
            inner_circle_margin = 30.0;
        }

        public override bool draw (Cairo.Context cr) {
            Gtk.Allocation allocation;
            get_allocation (out allocation);
            var width = allocation.width - 2 * padding_width - outer_arc_width;
            var height = allocation.height - 2 * padding_height - outer_arc_width;
            var min_size = width <= height ? width : height;
            var center_x = padding_width + width / 2 + outer_arc_width / 2;
            var center_y = padding_height + (3.0 / 5) * height + outer_arc_width / 2;
            var radius = min_size / 2;
            var inner_circle_radius = radius - outer_arc_width / 2 - inner_arc_width / 2 - inner_circle_margin;
            // Draw outer arc
            var out_pattern = new Cairo.Pattern.radial (
                center_x, center_y, radius - outer_arc_width / 2,
                center_x, center_y, radius);
            out_pattern.add_color_stop_rgba (0, 0.0, 0.129, 0.314, 0.75);
            out_pattern.add_color_stop_rgba (1, 0.0, 0.075, 0.176, 1);
            cr.set_source (out_pattern);
            cr.set_line_width (outer_arc_width);
            cr.arc (center_x, center_y, radius,angle_from ,angle_to );
            cr.stroke ();
            // Draw inner arc
            cr.set_source_rgba (0.0, 0.075, 0.176, 1);
            cr.set_line_width (inner_arc_width);
            cr.arc (center_x, center_y, radius - outer_arc_width / 2 - inner_arc_width / 2,angle_from ,angle_to );
            cr.stroke ();
            // Draw inner circle
            var circ_pattern = new Cairo.Pattern.radial (
                center_x, center_y, 0.75 * inner_circle_radius,
                center_x, center_y, inner_circle_radius);
            circ_pattern.add_color_stop_rgba (0, 0.0, 0.0, 0.0, 0.0);
            circ_pattern.add_color_stop_rgba (1, 1.0, 1.0, 1.0, 0.1);
            cr.set_source (circ_pattern);
            cr.arc (center_x, center_y, inner_circle_radius, 0, 2 * Math.PI);
            cr.fill ();
            // Paint inner text
            cr.set_line_width (5.0);
            cr.set_font_size (22);
            cr.select_font_face ("DejaVu Sans Mono", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
            cr.set_source_rgba (1.0, 1.0, 1.0, 0.6);
            Cairo.TextExtents text_extents;
            cr.text_extents (text, out text_extents);
            cr.move_to (
                center_x - text_extents.width / 2 - text_extents.x_bearing,
                center_y - text_extents.height / 2 - text_extents.y_bearing);
            cr.show_text (text);
            return false;
        }
    }
}