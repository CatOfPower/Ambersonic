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
    
    [GtkChild]
    private unowned Gtk.Label track_title_label;
    
    [GtkChild]
    private unowned Gtk.Scale track_progress;
    
    [GtkChild]
    private unowned Gtk.Image track_cover;

    private PlayerManager player_manager;
    private uint update_ui_timer_id = 0;

    public Window (Gtk.Application app) {
        Object (application: app);

        // Initialize player manager
        player_manager = PlayerManager.get_instance();
        
        // Connect player signals
        player_manager.song_changed.connect((title, artist, album, cover_art_id) => {
            track_title_label.label = title;
            
            if (cover_art_id != null && cover_art_id != "") {
                track_cover.set_from_pixbuf(Api.get_album_cover(cover_art_id));
            } else {
                track_cover.set_from_icon_name("audio-album-symbolic");
            }
        });
        
        player_manager.play_state_changed.connect((is_playing) => {
            update_play_button(is_playing);
        });
        
        player_manager.progress_changed.connect((position, duration) => {
            // Only update UI periodically to avoid excessive updates
            track_progress.adjustment.upper = duration;
            track_progress.set_value(position);
        });

        // Load albums
        Xml.Node album_list = Ambersonic.Api.get_album_list ("newest");

        unowned Xml.Node? album = album_list.children;
        while (album != null) {
            // Create a card for each album
            var album_card = new Ambersonic.AlbumCard (album);
            albums_box.append (album_card);
            album = album.next;
        }
        
        // Connect UI signals
        play_button.clicked.connect(() => {
            player_manager.toggle_play_pause();
        });
        
        // Set up track progress change handler
        track_progress.change_value.connect((scroll, value) => {
            // Note: Seeking not implemented in this basic player
            return false;
        });
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
        player_manager.toggle_play_pause();
    }
    
    private void update_play_button(bool is_playing) {
        if (is_playing) {
            play_button.set_icon_name("media-playback-pause-symbolic");
            play_button.set_tooltip_text(_("Pause"));
            play_button.add_css_class("suggested-action");
        } else {
            play_button.set_icon_name("media-playback-start-symbolic");
            play_button.set_tooltip_text(_("Play"));
            play_button.remove_css_class("suggested-action");
        }
    }
}