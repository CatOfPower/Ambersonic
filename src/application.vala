public class Ambersonic.Application : Adw.Application {
    private Ambersonic.Preferences preferences;
    private Ambersonic.Window window;

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
        this.window = (this.active_window as Ambersonic.Window) ?? new Ambersonic.Window (this);
        
        // Add the play_pause action after window is created
        var play_action = new SimpleAction ("play_pause", null);
        play_action.activate.connect (() => {
            window.play_pause ();
        });
        this.add_action (play_action);
        
        window.present ();
    }

    private void on_about_action () {
        string[] developers = { "CatOfPower" };
        var about = new Adw.AboutDialog () {
            application_name = "ambersonic",
            application_icon = "cat.of.power.Ambersonic",
            developer_name = "CatOfPower",
            translator_credits = _("translator-credits"),
            version = "0.1.0",
            developers = developers,
            copyright = "© 2025 CatOfPower",
            issue_url = "https://github.com/CatOfPower/Ambersonic/issues",
            website = "https://github.com/CatOfPower/Ambersonic",
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
