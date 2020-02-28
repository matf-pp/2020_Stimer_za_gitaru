namespace Strings.Widgets {
    public class Gauge: Gtk.DrawingArea {
        public uint padding_width { get; set; }
        public uint padding_height { get; set; }

        public double angle_from { get; set; }
        public double angle_to { get; set; }
        public double angle_diff { get; set; }
        public double outer_arc_width { get; set; }
        public double inner_arc_width { get; set; }
        public double inner_circle_margin { get; set; }

        public string text { get; set; }

        construct {
            padding_width = 5;
            padding_height = 5;
            angle_from = 3 * Math.PI / 4;
            angle_to = 9 * Math.PI / 4;
            angle_diff = (angle_to - angle_from) / 10;
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
            var radius = min_size / 2;
            var sin_from = Math.fabs (Math.sin (angle_from)), sin_to = Math.fabs (Math.sin (angle_to));
            var bot_arc_section = radius * (sin_from <= sin_to ? sin_to : sin_from);
            var inner_circle_radius = radius - outer_arc_width / 2 - inner_arc_width / 2 - inner_circle_margin;
            var center_x = padding_width + width / 2 + outer_arc_width / 2;
            // FIXME: Simplify calculation of center_y and remove magic_disp if possible
            var magic_disp = bot_arc_section + 1.6 * outer_arc_width;
            var min_disp = magic_disp < inner_circle_radius ? magic_disp : inner_circle_radius;
            var center_y = padding_height + 0.5 * height + 0.5 * outer_arc_width + 0.5 * (radius - min_disp);
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
            // Draw progress
            cr.set_line_width (0.4 * inner_arc_width);
            var inner_arc_radius = radius - outer_arc_width / 2 - inner_arc_width / 2;
            var cap_ang_diff = 2 * Math.asin (0.4 * inner_arc_width / (inner_arc_radius * 4));

            //  // DEBUG
            //  cr.set_source_rgba (1.0, 0.0, 0.0, 1.0);
            //  cr.set_line_cap (Cairo.LineCap.BUTT);
            //  cr.arc (center_x, center_y, inner_arc_radius, -Math.PI / 2, - Math.PI / 3);
            //  cr.stroke ();

            cr.set_source_rgba (1.0, 1.0, 1.0, 0.4);
            cr.set_line_cap (Cairo.LineCap.ROUND);
            cr.arc (center_x, center_y, inner_arc_radius, -Math.PI / 2 + cap_ang_diff, - Math.PI / 3 - cap_ang_diff);
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
            // Draw dashes and labels
            cr.set_line_width (3.0);
            cr.set_font_size (14);
            Gdk.RGBA textColorPrimary;
            var style_context = new Gtk.StyleContext ();
            style_context.lookup_color ("textColorPrimary", out textColorPrimary);
            cr.set_source_rgba (textColorPrimary.red, textColorPrimary.green, textColorPrimary.blue, textColorPrimary.alpha);
            cr.select_font_face ("DejaVu Sans Mono", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
            var angle_mid = (angle_from + angle_to) / 2;
            for (var phi = angle_from; phi <= angle_to; phi += angle_diff) {
                int cents = (int) ((phi - angle_mid) / (angle_to - angle_mid) * 50);
                var cents_text = "%dc".printf (cents);
                Cairo.TextExtents extents;
                cr.text_extents (cents_text, out extents);
                var x_phi = center_x + radius * Math.cos (phi) - extents.width / 2 - extents.x_bearing;
                var y_phi  = center_y + radius * Math.sin (phi) - extents.height / 2 - extents.y_bearing;
                cr.move_to (x_phi, y_phi);
                cr.show_text (cents_text);
                cr.stroke ();
            }
            return false;
        }
    }
}