public class Ambersonic.AlbumCard : Gtk.Box {
    public string title;
    public string artist;
    public string cover_art;

    public AlbumCard (Xml.Node album) {
        Object (orientation: Gtk.Orientation.HORIZONTAL, spacing: 12);

        this.title = title;
        this.artist = artist;
        this.cover_art = cover_art;

        this.add_css_class ("card");
        this.margin_bottom = 6;
        this.margin_start = 6;
        this.margin_end = 6;

        // Cover art
        var album_cover = new Gtk.Image ();
        album_cover.set_size_request (128, 128);
        album_cover.add_css_class ("br-6"); // border radius
        var album_cover_id = album.get_prop ("coverArt");
        if (album_cover_id != null) {
            album_cover.set_from_pixbuf (Ambersonic.Api.get_album_cover (album_cover_id));
        }

        // Album info box
        var info_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        info_box.halign = Gtk.Align.START;
        info_box.valign = Gtk.Align.CENTER;
        info_box.hexpand = true;

        // Album title
        var album_title = album.get_prop ("name") ?? album.get_prop ("title") ?? "Unknown Album";
        var title_label = new Gtk.Label (album_title);
        title_label.add_css_class ("title-2");
        title_label.halign = Gtk.Align.START;
        title_label.wrap = true;
        title_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
        title_label.lines = 2;
        title_label.ellipsize = Pango.EllipsizeMode.END;

        // Artist name
        var artist_name = album.get_prop ("artist") ?? "Unknown Artist";
        var artist_label = new Gtk.Label (artist_name);
        artist_label.add_css_class ("dim-label");
        artist_label.halign = Gtk.Align.START;
        artist_label.wrap = true;
        artist_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
        artist_label.lines = 1;
        artist_label.ellipsize = Pango.EllipsizeMode.END;

        var details = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);

        // Add all elements to the card
        info_box.append (title_label);
        info_box.append (artist_label);
        info_box.append (details);

        this.append (album_cover);
        this.append (info_box);

        // Add click behavior
        var gesture = new Gtk.GestureClick ();
        this.add_controller (gesture);
        var album_id = album.get_prop ("id");
        gesture.pressed.connect (() => {
            if (album_id != null) {
                // Get detailed album info
                var album_details = Ambersonic.Api.get_album (album_id);
                var album_view = new Ambersonic.AlbumView (album_details);
                
                // Replace main content with album view
                var main_window = this.get_root () as Ambersonic.Window;
                main_window.show_album_view (album_view);
            }
        });
    }
}