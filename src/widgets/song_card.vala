public class Ambersonic.SongCard : Gtk.Box {
    public string title;
    public string artist;
    public string cover_art;

    // Add these as class properties
    private Gtk.Label title_label;
    private Gtk.Label artist_label;
    private Gtk.Image song_cover;
    private Gtk.Label duration_label;

    public SongCard (Xml.Node song) {
        Object (orientation: Gtk.Orientation.HORIZONTAL, spacing: 12);

        this.add_css_class ("card");
        this.margin_bottom = 6;
        this.margin_start = 6;
        this.margin_end = 6;

        // Cover art
        song_cover = new Gtk.Image ();
        song_cover.set_size_request (128, 128);
        song_cover.add_css_class ("br-6"); // border radius
        var song_cover_id = song.get_prop ("coverArt");
        if (song_cover_id != null) {
            song_cover.set_from_pixbuf (Ambersonic.Api.get_album_cover (song_cover_id));
        }

        // Song info box
        var info_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        info_box.halign = Gtk.Align.START;
        info_box.valign = Gtk.Align.CENTER;
        info_box.hexpand = true;

        // Song title
        var song_title = song.get_prop ("name") ?? song.get_prop ("title") ?? "Unknown song";
        title_label = new Gtk.Label (song_title);
        title_label.add_css_class ("title-2");
        title_label.halign = Gtk.Align.START;
        title_label.wrap = true;
        title_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
        title_label.lines = 2;
        title_label.ellipsize = Pango.EllipsizeMode.END;

        // Artist name
        var artist_name = song.get_prop ("artist") ?? "Unknown Artist";
        artist_label = new Gtk.Label (artist_name);
        artist_label.add_css_class ("dim-label");
        artist_label.halign = Gtk.Align.START;
        artist_label.wrap = true;
        artist_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
        artist_label.lines = 1;
        artist_label.ellipsize = Pango.EllipsizeMode.END;

        var details = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);

        var duration = float.parse (song.get_prop ("duration") ?? "Unknown Duration") / 60;
        var duration_minutes = (int) Math.floor (duration);
        var duration_seconds = (int) Math.round ((duration - duration_minutes) * 60);
        duration_label = new Gtk.Label ("%d:%02d".printf (duration_minutes, duration_seconds));
        duration_label.add_css_class ("dim-label");
        duration_label.halign = Gtk.Align.START;
        details.append (duration_label);

        var album_name = song.get_prop ("album") ?? "Unknown Album";
        var album_label = new Gtk.Label (album_name);
        album_label.add_css_class ("dim-label");
        album_label.halign = Gtk.Align.START;
        details.append (album_label);

        // Add all elements to the card
        info_box.append (title_label);
        info_box.append (artist_label);
        info_box.append (details);

        this.append (song_cover);
        this.append (info_box);

        // Add click behavior
        var gesture = new Gtk.GestureClick ();
        this.add_controller (gesture);
        var song_id = song.get_prop ("id");
        gesture.pressed.connect (() => {
            if (song_id != null) {
                string url = Ambersonic.Api.get_stream_url (song_id);
                var main_window = this.get_root ().get_root () as Ambersonic.Window;
                main_window.player.url = url;
                main_window.is_playing = false;
                main_window.play_pause ();
            }
        });
    }

    public void update_from_node (Xml.Node song) {
        // Update the card with new song data
        var song_title = song.get_prop ("name") ?? song.get_prop ("title") ?? "Unknown Song";
        var artist_name = song.get_prop ("artist") ?? "Unknown Artist";
        var song_cover_id = song.get_prop ("coverArt");
        
        // Update existing widgets with new data
        title_label.label = song_title;
        artist_label.label = artist_name;
        
        if (song_cover_id != null) {
            song_cover.set_from_pixbuf (Ambersonic.Api.get_album_cover (song_cover_id));
        }
        
        // Update duration if available
        var duration = float.parse (song.get_prop ("duration") ?? "0") / 60;
        var duration_minutes = (int) Math.floor (duration);
        var duration_seconds = (int) Math.round ((duration - duration_minutes) * 60);
        duration_label.label = "%d:%02d".printf (duration_minutes, duration_seconds);
    }
}