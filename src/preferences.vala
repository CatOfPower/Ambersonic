[GtkTemplate (ui = "/cat/of/power/Ambersonic/preferences.ui")]
public class Ambersonic.Preferences : Adw.PreferencesDialog {
    [GtkChild]
    private unowned Adw.EntryRow address;
    private unowned Adw.EntryRow username;
    private unowned Adw.PasswordEntryRow password;
    private unowned Gtk.Button test_connection;

    private Settings settings;

    public Preferences () {
        Object ();

        settings = new Settings ("cat.of.power.Ambersonic");

        address.text = settings.get_string ("address");
        username.text = settings.get_string ("username");
        password.text = settings.get_string ("password");

        settings.bind ("address", address, "text", GLib.SettingsBindFlags.DEFAULT);
        settings.bind ("username", username, "text", GLib.SettingsBindFlags.DEFAULT);
        settings.bind ("password", password, "text", GLib.SettingsBindFlags.DEFAULT);

        this.closed.connect (() => {
            settings.apply ();
        });
    }
}
