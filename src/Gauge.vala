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

namespace Strings.Widgets {
    public class Gauge: Gtk.Container {
        public uint padding_width { get; set; }
        public uint padding_height { get; set; }

        public double angle_from { get; set; }
        public double angle_to { get; set; }
        public double angle_sections {get; set; }
        public double outer_arc_width { get; set; }
        public double inner_arc_width { get; set; }
        public double inner_circle_margin { get; set; }
        public double dash_length { get; set; }
        public double dash_width { get; set; }

        public double current_value { get; set; }
        public double domain { get; set; }

        protected Gtk.Widget inner_child = null;

        protected const double ANGLE_START = 1.5 * Math.PI;
        protected const double INNER_CIRCLE_GRADIENT_START = 0.75;

        construct {
            padding_width = 5;
            padding_height = 5;
            angle_from = 3 * Math.PI / 4;
            angle_to = 9 * Math.PI / 4;
            angle_sections = 10;
            outer_arc_width = 40.0;
            inner_arc_width = 20.0;
            inner_circle_margin = 30.0;
            dash_width = 7.0;
            dash_length = 10.0;
            domain = 50.0;
            base.set_has_window (false);
            base.set_can_focus (true);
            base.set_redraw_on_allocate (false);
        }

        protected struct DrawingContext {
            public double width;
            public double height;
            public double radius;
            public double center_x;
            public double center_y;
            public double inner_circle_radius;
            Gdk.RGBA text_color;
        }

        public override bool draw (Cairo.Context cr) {
            Gtk.Allocation allocation;
            get_allocation (out allocation);
            DrawingContext dc = calculate_drawing_context (ref allocation);
            draw_outer_arc (cr, ref dc);
            draw_inner_arc (cr, ref dc);
            draw_progress (cr, ref dc);
            draw_inner_circle (cr, ref dc);
            draw_dashes_and_labels (cr, ref dc);
            base.draw (cr);
            return false;
        }

        protected DrawingContext calculate_drawing_context (ref Gtk.Allocation allocation) {
            DrawingContext dc = { };
            dc.width = allocation.width - 2 * padding_width - outer_arc_width;
            dc.height = allocation.height - 2 * padding_height - outer_arc_width;
            dc.radius = (dc.width <= dc.height ? dc.width : dc.height) / 2;
            // TODO: Simplify calculation of center_y and remove magic_disp if possible
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
            var sty_ctx = get_style_context ();
            var flags = get_state_flags ();
            dc.text_color = (Gdk.RGBA) sty_ctx.get_property (Gtk.STYLE_PROPERTY_COLOR, flags);
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
                current_value / (2 * domain) * (angle_to - angle_from);
            debug ("Angle start: %lf", ANGLE_START);
            debug ("Angle from: %lf", angle_from);
            debug ("Angle to: %lf", angle_to);
            debug ("Current_value: %lf", current_value);
            debug ("Progress angle: %lf", progress_angle);
            var progress_from = progress_angle <= ANGLE_START ? progress_angle : ANGLE_START;
            var progress_to = progress_angle <= ANGLE_START ? ANGLE_START : progress_angle;
            if (progress_from < angle_from) { progress_from = angle_from; }
            if (progress_to > angle_to) { progress_to = angle_to; }
            progress_from += cap_ang_diff;
            progress_to -= cap_ang_diff;
            if (progress_to < progress_from) {
                var tmp = progress_from;
                progress_from = progress_to;
                progress_to = tmp;
            }
            cr.set_line_cap (Cairo.LineCap.ROUND);
            cr.set_source (create_conic_gradient (ref dc));
            cr.arc (dc.center_x, dc.center_y, inner_arc_radius, progress_from, progress_to);
            cr.stroke ();
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

        /** Adapted from
         * https://stackoverflow.com/questions/43230827/dynamiclly-growing-gradient-on-a-circle */
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
                dc.center_x, dc.center_y, INNER_CIRCLE_GRADIENT_START * dc.inner_circle_radius,
                dc.center_x, dc.center_y, dc.inner_circle_radius);
            circ_pattern.add_color_stop_rgba (0, 0.0, 0.0, 0.0, 0.0);
            circ_pattern.add_color_stop_rgba (1, dc.text_color.red, dc.text_color.green, dc.text_color.blue, 0.1);
            cr.set_source (circ_pattern);
            cr.arc (dc.center_x, dc.center_y, dc.inner_circle_radius, 0, 2 * Math.PI);
            cr.fill ();
        }

        protected void draw_dashes_and_labels (Cairo.Context cr, ref DrawingContext dc) {
            cr.set_font_size (14);
            cr.select_font_face ("sans-serif", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
            var angle_mid = (angle_from + angle_to) / 2;
            cr.set_line_cap (Cairo.LineCap.ROUND);
            cr.set_source_rgba (dc.text_color.red, dc.text_color.green, dc.text_color.blue, 0.6);
            var lbl_diff = calc_lbl_diff (cr, ref dc);
            var a_from = angle_from + lbl_diff;
            var a_to = angle_to - lbl_diff;
            var angle_diff = (a_to - a_from) / angle_sections;
            /* NOTE: added lbl_diff * 0.5 to resolve floating-point errors causing the last label
             * not to be displayed. */
            for (var phi = a_from; phi <= a_to + lbl_diff * 0.5; phi += angle_diff) {
                // Draw dashes
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
                int cents = (int) Math.round ((phi - angle_mid) / (a_to - angle_mid) * domain);
                var cents_text = "%dc".printf (cents);
                Cairo.TextExtents extents;
                cr.text_extents (cents_text, out extents);
                cr.move_to (x_phi - extents.width / 2 - extents.x_bearing,
                            y_phi - extents.height / 2 - extents.y_bearing);
                cr.show_text (cents_text);
                cr.stroke ();
            }
        }

        // TODO: Simplify if possible
        // NOTE: Calling this makes sense only after setting font properties in Cairo.Context.
        protected double calc_lbl_diff (Cairo.Context cr, ref DrawingContext dc) {
            Cairo.TextExtents extents;
            cr.text_extents ("-%ldc".printf ((long) domain), out extents);
            var x_lbl = dc.center_x + dc.radius * Math.cos (angle_from) + extents.width / 2;
            var y_lbl = dc.center_y + dc.radius * Math.sin (angle_from) + extents.height / 2;
            var d_x = x_lbl - dc.center_x;
            var d_y = y_lbl - dc.center_y;
            var r = Math.sqrt (d_x * d_x + d_y * d_y);
            var x_from = dc.center_x + r * Math.cos (angle_from);
            var y_from = dc.center_y + r * Math.sin (angle_from);
            d_x = x_from - x_lbl;
            d_y = y_from - y_lbl;
            var dist_sqr = d_x * d_x + d_y * d_y;
            return Math.acos ((2 * r * r - dist_sqr) / (2 * r * r));
        }

        public override void add (Gtk.Widget widget) {
            if (inner_child != null) { return; }
            widget.set_parent (this);
            inner_child = widget;
        }

        public override void remove (Gtk.Widget widget) {
            if (inner_child != widget) { return; }
            widget.unparent ();
            inner_child = null;
            if (get_visible () && widget.get_visible ()) {
                queue_resize_no_redraw ();
            }
        }

        public override void forall_internal (bool include_internals, Gtk.Callback callback) {
            if (inner_child != null) { callback (inner_child); }
        }

        public override Gtk.SizeRequestMode get_request_mode () {
            return inner_child != null ?
                inner_child.get_request_mode ():
                Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
        }

        public override void size_allocate (Gtk.Allocation allocation) {
            DrawingContext dc = calculate_drawing_context (ref allocation);
            var side = INNER_CIRCLE_GRADIENT_START * dc.inner_circle_radius * Math.SQRT2;
            Gtk.Allocation child_allocation = Gtk.Allocation ();
            if (inner_child != null && inner_child.get_visible ()) {
                child_allocation.x = (int) (dc.center_x - 0.5 * side);
                child_allocation.y = (int) (dc.center_y - 0.5 * side);
                child_allocation.width = (int) side;
                child_allocation.height = (int) side;
                inner_child.size_allocate (child_allocation);
                if (get_realized ()) { inner_child.show (); }
            }
            if (get_realized () && inner_child != null) {
                inner_child.set_child_visible (true);
            }
            base.size_allocate (allocation);
        }

        public new void get_preferred_size (out Gtk.Requisition minimum_size,
                                            out Gtk.Requisition natural_size)
        {
            Gtk.Requisition child_minimum_size = { 0, 0 };
            Gtk.Requisition child_natural_size = { 0, 0 };
            if (inner_child != null && inner_child.get_visible ()) {
                inner_child.get_preferred_size (out child_minimum_size, out child_natural_size);
            }
            minimum_size = { 0, 0 };
            natural_size = { 0, 0 };
            natural_size.width = child_natural_size.width;
            natural_size.height = child_natural_size.height;
        }
    }
}
