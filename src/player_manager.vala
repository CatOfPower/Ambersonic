namespace Ambersonic {
    public class PlayerManager : Object {
        private static PlayerManager? instance = null;
        public AudioPlayer player { get; private set; }
        
        // Current track information
        public string current_song_id { get; private set; }
        public string current_title { get; private set; }
        public string current_artist { get; private set; }
        public string current_album { get; private set; }
        public string current_cover_art_id { get; private set; }
        public uint64 current_duration { get; private set; }
        
        // Signals
        public signal void song_changed(string title, string artist, string album, string cover_art_id);
        public signal void play_state_changed(bool is_playing);
        public signal void progress_changed(double position, double duration);
        public signal void buffering_progress(double progress);
        
        private PlayerManager() {
            player = new AudioPlayer();
            
            // Connect signals
            player.playback_started.connect(() => {
                play_state_changed(true);
            });
            
            player.playback_stopped.connect(() => {
                play_state_changed(false);
            });
            
            player.playback_paused.connect(() => {
                play_state_changed(false);
            });
            
            player.track_changed.connect((title, artist) => {
                // Already handled in play_song
            });
            
            player.position_changed.connect((pos, dur) => {
                progress_changed((double)pos / 1000.0, (double)dur / 1000.0);
            });
            
            player.buffer_progress.connect((progress) => {
                buffering_progress(progress);
            });
        }
        
        public static PlayerManager get_instance() {
            if (instance == null) {
                instance = new PlayerManager();
            }
            return instance;
        }
        
        public void play_song(string song_id) {
            // Get song information from API
            Xml.Node song = Api.get_song(song_id);
            if (song == null) {
                warning("Failed to get song information for ID: %s", song_id);
                return;
            }
            
            // Extract song details
            current_song_id = song_id;
            current_title = song.get_prop("title") ?? song.get_prop("name") ?? "Unknown Title";
            current_artist = song.get_prop("artist") ?? "Unknown Artist";
            current_album = song.get_prop("album") ?? "Unknown Album";
            current_cover_art_id = song.get_prop("coverArt") ?? "";
            
            // Parse duration
            var duration_str = song.get_prop("duration") ?? "0";
            double duration_seconds = double.parse(duration_str);
            current_duration = (uint64)(duration_seconds * 1000); // Convert to milliseconds
            
            // Get stream URL
            string stream_url = Api.get_stream_url(song_id);
            
            // Load and play the song
            player.set_duration(current_duration);
            player.load_and_play(stream_url, current_title, current_artist, song_id);
            
            // Emit signal that song has changed
            song_changed(current_title, current_artist, current_album, current_cover_art_id);
        }
        
        public void toggle_play_pause() {
            if (player.playing) {
                player.pause();
            } else if (current_song_id != null && current_song_id != "") {
                player.resume();
            }
        }
        
        public void stop() {
            player.stop();
        }
        
        public bool is_playing() {
            return player.playing;
        }
    }
}