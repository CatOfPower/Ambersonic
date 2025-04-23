[GtkTemplate (ui = "/cat/of/power/Ambersonic/blueprints/preferences.ui")]
public class Ambersonic.Preferences : Adw.PreferencesDialog {
    [GtkChild]
    private unowned Adw.EntryRow address;
    [GtkChild]
    private unowned Adw.EntryRow username;
    [GtkChild]
    private unowned Adw.PasswordEntryRow password;
    [GtkChild]
    private unowned Gtk.Button test_connection;

    private Settings settings;

    public Preferences () {
        Object ();

        settings = new Settings ("cat.of.power.Ambersonic");

        test_connection.clicked.connect (() => {
            this.on_test_connection_clicked ();
        });

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

    public void on_test_connection_clicked () {
        var connection_status = Ambersonic.Api.check_connection ();
        
        if (connection_status > 0) {
            if (connection_status == 1) {
                this.test_connection.set_label ("Connection successful");
            } else {
                this.test_connection.set_label ("Incorrect username or password");
            }
        } else {
            this.test_connection.set_label ("Connection failed");
        }
    }
}
