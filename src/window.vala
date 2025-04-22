[GtkTemplate (ui = "/cat/of/power/Ambersonic/window.ui")]
public class Ambersonic.Window : Adw.ApplicationWindow {
    [GtkChild]
    private unowned Gtk.Box main_box;

    public Window (Gtk.Application app) {
        Object (application: app);

        Xml.Node album_list = Ambersonic.Api.get_album_list ("newest");

        unowned Xml.Node? album = album_list.children;
        while (album != null) {
            var album_title = album.get_prop ("title");
            var album_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
            var album_cover = new Gtk.Image ();
            album_cover.set_valign (Gtk.Align.CENTER);
            album_cover.set_halign (Gtk.Align.CENTER);
            album_cover.set_size_request (128, 128);
            var album_title_label = new Gtk.Label (album_title);
            var album_cover_id = album.get_prop ("coverArt");
            album_cover.set_from_pixbuf (Ambersonic.Api.get_album_cover (album_cover_id));
            
            main_box.append (album_box);
            album_box.append (album_cover);
            album_box.append (album_title_label);
            album = album.next;
        }
    }
}
