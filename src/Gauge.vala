namespace Strings.Widgets {
    public class Gauge: Gtk.DrawingArea {
        public override bool draw (Cairo.Context cr) {
            Gtk.Allocation allocation;
            get_allocation (out allocation);
            cr.set_line_width (1);
            cr.set_source_rgba (255, 255, 0, 1);
            cr.save ();
            cr.scale (allocation.width, allocation.height);
            cr.move_to (0, 0);
            cr.line_to (1, 1);
            cr.restore ();
            cr.stroke ();
            cr.select_font_face ("DejaVu Sans Mono", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
            cr.set_font_size (18);
            string message = _("Hello, World :)");
            Cairo.TextExtents extents;
            cr.text_extents (message, out extents);
            double x = allocation.width / 2 - extents.width / 2 - extents.x_bearing;
            double y = allocation.height / 2 - extents.height / 2 - extents.y_bearing;
            cr.move_to (x, y);
            cr.show_text (message);
            return false;
        }
    }
}