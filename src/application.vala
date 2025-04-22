
public class Ambersonic.Application : Adw.Application {
    private Ambersonic.Preferences preferences;

    public Application () {
        Object (
            application_id: "cat.of.power.Ambersonic",
            flags: ApplicationFlags.DEFAULT_FLAGS,
            resource_base_path: "/cat/of/power/Ambersonic"
        );
    }

    construct {
        ActionEntry[] action_entries = {
            { "about", this.on_about_action },
            { "preferences", this.on_preferences_action },
            { "quit", this.quit }
        };
        this.add_action_entries (action_entries, this);
        this.set_accels_for_action ("app.quit", {"<primary>q"});
    }

    public override void activate () {
        base.activate ();
        var win = this.active_window ?? new Ambersonic.Window (this);
        win.present ();
    }

    private void on_about_action () {
        string[] developers = { "Alex" };
        var about = new Adw.AboutDialog () {
            application_name = "ambersonic",
            application_icon = "cat.of.power.Ambersonic",
            developer_name = "Alex",
            translator_credits = _("translator-credits"),
            version = "0.1.0",
            developers = developers,
            copyright = "© 2025 Alex",
        };

        about.present (this.active_window);
    }

    private void on_preferences_action () {
        if (preferences == null) {
            preferences = new Ambersonic.Preferences ();
        }

        preferences.present (this.active_window);
    }
}
