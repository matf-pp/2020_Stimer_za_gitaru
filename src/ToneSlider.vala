namespace Strings.Widgets {
    public class ToneSlider : Gtk.DrawingArea {
        public override bool draw (Cairo.Context cr) {
            Gtk.Allocation allocation;
            get_allocation (out allocation);
            allocation.height = 48;
            size_allocate (allocation);
            //  set_size_request (0, 48);
            //  cr.move_to (allocation.width / 2, allocation.height / 2);
            //  cr.set_line_width (5.0);
            //  cr.set_font_size (22);
            //  cr.select_font_face ("DejaVu Sans Mono", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
            //  cr.set_source_rgba (1.0, 1.0, 1.0, 0.6);
            //  cr.show_text ("Test");
            return false;
        }
    } 
}