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
        public double dash_length { get; set; }
        public double dash_width { get; set; }

        public double current_value { get; set; }
        public double target_value { get; set; }
        public double domain { get; set; }

        protected const double ANGLE_START = 1.5 * Math.PI;

        construct {
            padding_width = 5;
            padding_height = 5;
            angle_from = 3 * Math.PI / 4;
            angle_to = 9 * Math.PI / 4;
            angle_diff = (angle_to - angle_from) / 8;
            outer_arc_width = 40.0;
            inner_arc_width = 20.0;
            inner_circle_margin = 30.0;
            dash_width = 7.0;
            dash_length = 10.0;
            domain = 100.0;
        }

        protected struct DrawingContext {
            public double width;
            public double height;
            public double radius;
            public double center_x;
            public double center_y;
            public double inner_circle_radius;
        }

        public override bool draw (Cairo.Context cr) {
            DrawingContext dc = calculate_drawing_context ();
            draw_outer_arc (cr, ref dc);
            draw_inner_arc (cr, ref dc);
            draw_progress (cr, ref dc);
            draw_inner_circle (cr, ref dc);
            draw_inner_text (cr, ref dc);
            draw_dashes_and_labels (cr, ref dc);
            return false;
        }

        protected DrawingContext calculate_drawing_context () {
            DrawingContext dc = { };
            Gtk.Allocation allocation;
            get_allocation (out allocation);
            dc.width = allocation.width - 2 * padding_width - outer_arc_width;
            dc.height = allocation.height - 2 * padding_height - outer_arc_width;
            dc.radius = (dc.width <= dc.height ? dc.width : dc.height) / 2;
            // FIXME: Simplify calculation of center_y and remove magic_disp if possible
            var sin_from = Math.fabs (Math.sin (angle_from));
            var sin_to = Math.fabs (Math.sin (angle_to));
            var bot_arc_section = dc.radius * (sin_from <= sin_to ? sin_to : sin_from);
            dc.inner_circle_radius = dc.radius - outer_arc_width / 2 -
                                     inner_arc_width / 2 - inner_circle_margin;
            var magic_disp = bot_arc_section + 1.6 * outer_arc_width;
            var min_disp = magic_disp < dc.inner_circle_radius ?
                           magic_disp : dc.inner_circle_radius;
            dc.center_x = padding_width + dc.width / 2 + outer_arc_width / 2;
            dc.center_y = padding_height + 0.5 * dc.height +
                          0.5 * outer_arc_width + 0.5 * (dc.radius - min_disp);
            return dc;
        }

        protected void draw_outer_arc (Cairo.Context cr, ref DrawingContext dc) {
            var out_pattern = new Cairo.Pattern.radial (
                dc.center_x, dc.center_y, dc.radius - outer_arc_width / 2,
                dc.center_x, dc.center_y, dc.radius);
            out_pattern.add_color_stop_rgba (0, 0.0, 0.129, 0.314, 0.75);
            out_pattern.add_color_stop_rgba (1, 0.0, 0.075, 0.176, 1);
            cr.set_source (out_pattern);
            cr.set_line_width (outer_arc_width);
            cr.arc (dc.center_x, dc.center_y, dc.radius, angle_from, angle_to);
            cr.stroke ();
        }

        protected void draw_inner_arc (Cairo.Context cr, ref DrawingContext dc) {
            cr.set_source_rgba (0.0, 0.075, 0.176, 1);
            cr.set_line_width (inner_arc_width);
            cr.arc (dc.center_x, dc.center_y,
                    dc.radius - outer_arc_width / 2 - inner_arc_width / 2,
                    angle_from, angle_to);
            cr.stroke ();
        }

        protected void draw_progress (Cairo.Context cr, ref DrawingContext dc) {
            cr.set_line_width (0.4 * inner_arc_width);
            var inner_arc_radius = dc.radius - outer_arc_width / 2 - inner_arc_width / 2;
            var cap_ang_diff = 2 * Math.asin (0.4 * inner_arc_width / (inner_arc_radius * 4));
            var progress_angle = ANGLE_START +
                (current_value - target_value) / (2 * domain) * (angle_to - angle_from);
            var progress_from = progress_angle <= ANGLE_START ? progress_angle : ANGLE_START;
            var progress_to = progress_angle <= ANGLE_START ? ANGLE_START : progress_angle;
            if (progress_from == progress_to) { return; }
            progress_from += cap_ang_diff;
            progress_to -= cap_ang_diff;
            if (progress_to < progress_from) {
                var tmp = progress_from;
                progress_from = progress_to;
                progress_to = tmp;
            }
            cr.set_line_cap (Cairo.LineCap.ROUND);
            //  cr.set_source_rgba (1.0, 1.0, 1.0, 0.4);
            cr.set_source (create_conic_gradient (ref dc));
            cr.arc (dc.center_x, dc.center_y, inner_arc_radius, progress_from, progress_to);
            cr.stroke ();
            // DEBUG:
            //  cr.arc (dc.center_x, dc.center_y, inner_arc_radius,
            //          0, 2 * Math.PI);
            //  cr.stroke ();
            //  cr.fill ();
        }

        protected Cairo.MeshPattern create_conic_gradient (ref DrawingContext dc) {
            var pattern = new Cairo.MeshPattern ();
            // good = #12B4EC, meh = #F350F4, bad = #D96D22
            Gdk.RGBA good = { 0.07058823529411765, 0.7058823529411765, 0.9254901960784314, 1.0 };
            Gdk.RGBA meh =  { 0.9529411764705882, 0.3137254901960784, 0.9568627450980393, 1.0 };
            Gdk.RGBA bad =  { 1.9908256880733946, 0.3137254901960784, 0.13333333333333333, 1.0 };
            var angle_pc = 0.25 * (angle_to - angle_from);
            double[] angles = {
                angle_from + angle_pc, angle_from + 2 * angle_pc, angle_from + 3 * angle_pc
            };
            pattern_add_conic_sector (pattern, ref dc, angle_from, angles[0], bad, meh);
            pattern_add_conic_sector (pattern, ref dc, angles[0], angles[1], meh, good);
            pattern_add_conic_sector (pattern, ref dc, angles[1], angles[2], good, meh);
            pattern_add_conic_sector (pattern, ref dc, angles[2], angle_to, meh, bad);
            return pattern;
        }

        // Adapted from https://stackoverflow.com/questions/43230827/dynamiclly-growing-gradient-on-a-circle
        protected void pattern_add_conic_sector (
            Cairo.MeshPattern pattern,
            ref DrawingContext dc,
            double angle_from, double angle_to,
            Gdk.RGBA from, Gdk.RGBA to
        ) {
            var r_sin_from = dc.radius * Math.sin (angle_from);
            var r_cos_from = dc.radius * Math.cos (angle_from);
            var r_sin_to = dc.radius * Math.sin (angle_to);
            var r_cos_to = dc.radius * Math.cos (angle_to);
            var h = 4.0 / 3.0 * Math.tan ((angle_to - angle_from) / 4.0);
            pattern.begin_patch ();
            pattern.move_to (dc.center_x, dc.center_y);
            pattern.line_to (dc.center_x + r_cos_from, dc.center_y + r_sin_from);
            pattern.curve_to (
                dc.center_x + r_cos_from - h * r_sin_from,
                dc.center_y + r_sin_from + h * r_cos_from,
                dc.center_x + r_cos_to + h * r_sin_to,
                dc.center_y + r_sin_to - h * r_cos_to,
                dc.center_x + r_cos_to,
                dc.center_y + r_sin_to);
            pattern.set_corner_color_rgba (0, from.red, from.green, from.blue, from.alpha);
            pattern.set_corner_color_rgba (1, from.red, from.green, from.blue, from.alpha);
            pattern.set_corner_color_rgba (2, to.red, to.green, to.blue, to.alpha);
            pattern.set_corner_color_rgba (3, to.red, to.green, to.blue, to.alpha);
            pattern.end_patch ();
        }

        protected void draw_inner_circle (Cairo.Context cr, ref DrawingContext dc) {
            var circ_pattern = new Cairo.Pattern.radial (
                dc.center_x, dc.center_y, 0.75 * dc.inner_circle_radius,
                dc.center_x, dc.center_y, dc.inner_circle_radius);
            circ_pattern.add_color_stop_rgba (0, 0.0, 0.0, 0.0, 0.0);
            circ_pattern.add_color_stop_rgba (1, 1.0, 1.0, 1.0, 0.1);
            cr.set_source (circ_pattern);
            cr.arc (dc.center_x, dc.center_y, dc.inner_circle_radius, 0, 2 * Math.PI);
            cr.fill ();
        }

        protected void draw_inner_text (Cairo.Context cr, ref DrawingContext dc) {
            cr.set_line_width (5.0);
            cr.set_font_size (22);
            cr.select_font_face ("DejaVu Sans Mono", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
            cr.set_source_rgba (1.0, 1.0, 1.0, 0.6);
            var tgt_value_text = "%.2lf Hz".printf (current_value);
            Cairo.TextExtents text_extents;
            cr.text_extents (tgt_value_text, out text_extents);
            cr.move_to (
                dc.center_x - text_extents.width / 2 - text_extents.x_bearing,
                dc.center_y - text_extents.height / 2 - text_extents.y_bearing);
            cr.show_text (tgt_value_text);
        }

        protected void draw_dashes_and_labels (Cairo.Context cr, ref DrawingContext dc) {
            cr.set_line_width (3.0);
            cr.set_font_size (14);
            Gdk.RGBA textColorPrimary;
            var style_context = new Gtk.StyleContext ();
            style_context.lookup_color ("textColorPrimary", out textColorPrimary);
            cr.select_font_face ("DejaVu Sans Mono", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
            var angle_mid = (angle_from + angle_to) / 2;
            cr.set_line_cap (Cairo.LineCap.ROUND);
            cr.set_source_rgba (1.0, 1.0, 1.0, 0.6);
            for (var phi = angle_from; phi <= angle_to; phi += angle_diff) {
                // Draw dashes
                //  cr.set_source_rgba (textColorPrimary.red, textColorPrimary.green,
                //                      textColorPrimary.blue, textColorPrimary.alpha);
                cr.set_line_width (dash_width);
                var x_phi = dc.center_x + dc.radius * Math.cos (phi);
                var y_phi  = dc.center_y + dc.radius * Math.sin (phi);
                var x_from = x_phi + 0.5 * (outer_arc_width + dash_width) * Math.cos (phi);
                var y_from = y_phi + 0.5 * (outer_arc_width + dash_width) * Math.sin (phi);
                cr.move_to (x_from, y_from);
                cr.line_to (x_from + dash_length * Math.cos (phi),
                            y_from + dash_length * Math.sin (phi));
                cr.stroke ();
                // Draw labels
                cr.set_line_width (3.0);
                int cents = (int) Math.round ((phi - angle_mid) / (angle_to - angle_mid) * domain);
                var cents_text = "%dc".printf (cents);
                Cairo.TextExtents extents;
                cr.text_extents (cents_text, out extents);
                cr.move_to (x_phi - extents.width / 2 - extents.x_bearing,
                            y_phi - extents.height / 2 - extents.y_bearing);
                cr.show_text (cents_text);
                cr.stroke ();
            }
        }
    }
}