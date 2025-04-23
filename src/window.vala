[GtkTemplate (ui = "/cat/of/power/Ambersonic/window.ui")]
public class Ambersonic.Window : Adw.ApplicationWindow {
    [GtkChild]
    private unowned Gtk.Box main_box;
    
    [GtkChild]
    private unowned Gtk.Box albums_box;

    public Window (Gtk.Application app) {
        Object (application: app);

        Xml.Node album_list = Ambersonic.Api.get_album_list ("newest");

        unowned Xml.Node? album = album_list.children;
        while (album != null) {
            // Create a card for each album
            var album_card = new Ambersonic.AlbumCard (album);
            albums_box.append (album_card);
            album = album.next;
        }
    }
}
