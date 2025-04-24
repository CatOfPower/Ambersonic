using Gst;

public class Ambersonic.Player : GLib.Object {
    private dynamic Gst.Element playbin;
    private bool is_playing = false;
    private string _url = "";
    private bool is_seeking = false;  // Flag to track seeking state
    
    // Property for URL
    public string url {
        get {
            return _url;
        }
        set {
            _url = value;
            playbin.set_state (Gst.State.NULL);
            playbin.uri = _url;
        }
    }
    
    // Constructor
    public Player () {
        // Initialize GStreamer
        unowned string[] args = null;
        Gst.init (ref args);
        
        // Create playbin element
        playbin = Gst.ElementFactory.make ("playbin", "player");
        if (playbin == null) {
            stderr.printf ("Error creating playbin element\n");
            return;
        }
        
        // Create bus to receive messages
        Gst.Bus bus = playbin.get_bus ();
        bus.add_watch (0, (bus, message) => {
            switch (message.type) {
                case Gst.MessageType.EOS:
                    // End of stream
                    playbin.set_state (Gst.State.NULL);
                    is_playing = false;
                    break;
                case Gst.MessageType.ERROR:
                    GLib.Error err;
                    string debug;
                    message.parse_error (out err, out debug);
                    stderr.printf ("Error: %s\n", err.message);
                    playbin.set_state (Gst.State.NULL);
                    is_playing = false;
                    break;
                case Gst.MessageType.ASYNC_DONE:
                    // Seeking operation completed
                    if (is_seeking) {
                        is_seeking = false;
                    }
                    break;
                default:
                    break;
            }
            return true;
        });
    }
    
    // Play method
    public void play () {
        if (url == "") {
            stderr.printf ("Error: No URL set\n");
            return;
        }
        
        playbin.set_state (Gst.State.PLAYING);
        is_playing = true;
    }
    
    // Pause method
    public void pause () {
        if (is_playing) {
            playbin.set_state (Gst.State.PAUSED);
            is_playing = false;
        }
    }
    
    // Set position method (in seconds)
    public void set_position (int64 seconds) {
        if (playbin == null) return;
        
        // Set seeking flag to true
        is_seeking = true;
        
        // Convert seconds to nanoseconds for GStreamer
        int64 position = seconds * Gst.SECOND;
        playbin.seek_simple (Gst.Format.TIME, Gst.SeekFlags.FLUSH | Gst.SeekFlags.KEY_UNIT, position);
    }
    
    // Get position method (returns seconds)
    public int64 get_position () {
        if (playbin == null) return 0;
        if (is_seeking) return -1;  // Skip getting position during seek
        
        int64 position;
        Gst.Format format = Gst.Format.TIME;
        
        if (!playbin.query_position (format, out position)) {
            stderr.printf ("Could not query position\n");
            return 0;
        }
        
        // Convert from nanoseconds to seconds
        return position / Gst.SECOND;
    }

    public int64 get_duration () {
        if (playbin == null) return 0;
        
        int64 duration;
        Gst.Format format = Gst.Format.TIME;
        
        if (!playbin.query_duration (format, out duration)) {
            stderr.printf ("Could not query duration\n");
            return 0;
        }
        
        // Convert from nanoseconds to seconds
        return duration / Gst.SECOND;
    }

    public signal void position_updated (int64 position, int64 duration);

    public void start_position_monitoring () {
        Timeout.add (1000, () => {
            if (is_playing && !is_seeking) {  // Only update position if not seeking
                int64 pos = get_position();
                if (pos >= 0) {  // Only emit signal if position is valid
                    position_updated (pos, get_duration ());
                }
            }
            return true;
        });
    }
}