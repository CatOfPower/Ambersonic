[GtkTemplate (ui = "/cat/of/power/Ambersonic/preferences.ui")]
public class Ambersonic.Preferences : Adw.PreferencesDialog {
    [GtkChild]
    private unowned Adw.EntryRow address;
    private unowned Adw.EntryRow username;
    private unowned Adw.PasswordEntryRow password;
    private unowned Gtk.Button test_connection;

    public Preferences () {
        Object ();
    }
}
