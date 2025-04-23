[GtkTemplate (ui = "/cat/of/power/Ambersonic/blueprints/album_view.ui")]
public class Ambersonic.AlbumView : Gtk.Box {
    [GtkChild]
    private unowned Gtk.Picture album_cover;
    
    [GtkChild]
    private unowned Gtk.Label album_title;
    
    [GtkChild]
    private unowned Gtk.Label artist_name;
    
    [GtkChild]
    private unowned Gtk.Label album_year;
    
    [GtkChild]
    private unowned Gtk.Box songs_box;

    [GtkChild]
    private unowned Gtk.Button back_button;

    public AlbumView (Xml.Node album) {
        Object ();
        
        // Add back button handler
        back_button.clicked.connect (() => {
            var main_window = (Ambersonic.Window) this.get_root();
            if (main_window != null) {
                this.unparent ();
                main_window.show_albums_list ();
            } else {
                warning ("Could not get main window reference");
            }
        });

        // Set album details
        album_title.label = album.get_prop ("name") ?? "Unknown Album";
        artist_name.label = album.get_prop ("artist") ?? "Unknown Artist";
        album_year.label = album.get_prop ("year") ?? "";
        
        // Set album cover
        var cover_art_id = album.get_prop ("coverArt");
        if (cover_art_id != null) {
            var pixbuf = Ambersonic.Api.get_album_cover (cover_art_id);
            album_cover.set_pixbuf (pixbuf);
        }
        
        // Add songs
        unowned Xml.Node? song = album.children;
        while (song != null) {
            if (song.name == "song") {
                var song_card = new Ambersonic.SongCard (song);
                songs_box.append (song_card);
            }
            song = song.next;
        }
    }
}