[GtkTemplate (ui = "/cat/of/power/Ambersonic/window.ui")]
public class Ambersonic.Window : Adw.ApplicationWindow {
    [GtkChild]
    private unowned Gtk.Label label;

    public Window (Gtk.Application app) {
        Object (application: app);
    }
}
