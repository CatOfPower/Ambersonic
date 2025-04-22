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
            var album_card = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            album_card.add_css_class ("card");
            album_card.margin_bottom = 6;
            album_card.margin_start = 6;
            album_card.margin_end = 6;
            
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

            // Year and genre (if available)
            var details = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            var year = album.get_prop ("year");
            if (year != null) {
                var year_label = new Gtk.Label (year);
                year_label.add_css_class ("caption");
                year_label.add_css_class ("dim-label");
                details.append (year_label);
            }

            var genre = album.get_prop ("genre");
            if (genre != null) {
                var genre_label = new Gtk.Label (genre);
                genre_label.add_css_class ("caption");
                genre_label.add_css_class ("dim-label");
                details.append (genre_label);
            }

            // Add all elements to the card
            info_box.append (title_label);
            info_box.append (artist_label);
            info_box.append (details);

            album_card.append (album_cover);
            album_card.append (info_box);

            // Add click behavior
            var gesture = new Gtk.GestureClick ();
            album_card.add_controller (gesture);
            var album_id = album.get_prop ("id");
            gesture.pressed.connect (() => {
                if (album_id != null) {
                    // TODO: Implement album details view
                    print ("Album clicked: %s\n", album_id);
                }
            });

            albums_box.append (album_card);
            album = album.next;
        }
    }
}
