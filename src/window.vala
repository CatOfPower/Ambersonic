[GtkTemplate (ui = "/cat/of/power/Ambersonic/blueprints/window.ui")]
public class Ambersonic.Window : Adw.ApplicationWindow {
    [GtkChild]
    private unowned Gtk.Box main_box;
    
    [GtkChild]
    private unowned Gtk.Box albums_box;

    [GtkChild]
    private unowned Gtk.Box player_box;

    [GtkChild]
    private unowned Gtk.Button play_button;

    public unowned bool is_playing = false;
    public Ambersonic.Player player;

    public Window (Gtk.Application app) {
        Object (application: app);

        player = new Ambersonic.Player ();

        Xml.Node album_list = Ambersonic.Api.get_album_list ("newest");

        unowned Xml.Node? album = album_list.children;
        while (album != null) {
            // Create a card for each album
            var album_card = new Ambersonic.AlbumCard (album);
            albums_box.append (album_card);
            album = album.next;
        }
    }

    public void show_album_view (AlbumView album_view) {
        main_box.get_first_child ().unparent ();
        
        main_box.append (album_view);
        player_box.unparent ();
        main_box.append (player_box);
    }

    public void show_albums_list () {
        // Store reference to ScrolledWindow
        var scrolled = main_box.get_first_child () as Gtk.ScrolledWindow;
        if (scrolled != null) {
            scrolled.unparent ();
        }
        
        // Create new ScrolledWindow if needed
        if (scrolled == null) {
            scrolled = new Gtk.ScrolledWindow ();
            scrolled.set_child (albums_box);
        }
        
        // Add back the scrolled window containing albums box
        main_box.append (scrolled);
        player_box.unparent ();
        main_box.append (player_box);
    }

    public void play_pause () {
        if (is_playing) {
            is_playing = false;
            play_button.set_icon_name ("media-playback-start-symbolic");
            play_button.set_tooltip_text (_("Play"));
            play_button.remove_css_class ("suggested-action");
            player.pause ();
        } else {
            if (player.url == "") {
                return;
            }
            
            is_playing = true;
            play_button.set_icon_name ("media-playback-pause-symbolic");
            play_button.set_tooltip_text (_("Pause"));
            play_button.add_css_class ("suggested-action");
            player.play ();
        }
    }
}
