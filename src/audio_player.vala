namespace Ambersonic {
    public class AudioPlayer : Object {
        // Signals
        public signal void playback_started();
        public signal void playback_stopped();
        public signal void playback_paused();
        public signal void track_changed(string title, string artist);
        public signal void position_changed(uint64 position, uint64 duration);
        public signal void buffer_progress(double progress);
        
        private Canberra.Context context;
        private Soup.Session session;
        private FileIOStream temp_stream;
        private File temp_file;
        private InputStream input_stream;
        private Cancellable cancellable;
        private bool is_playing = false;
        private uint64 position = 0;
        private uint64 duration = 0;
        private uint position_timer_id = 0;
        private uint buffer_timer_id = 0;
        private int64 bytes_received = 0;
        private int64 content_length = 0;
        private bool download_completed = false;
        
        // Current track info
        private string current_title = "";
        private string current_artist = "";
        private string current_song_id = "";
        
        public bool playing {
            get { return is_playing; }
        }
        
        public AudioPlayer() {
            try {
                Canberra.Context.create(out context);
                session = new Soup.Session();
                session.timeout = 15;
                cancellable = new Cancellable();
            } catch (Error e) {
                warning("Error initializing audio player: %s", e.message);
            }
        }
        
        public void load_and_play(string stream_url, string title, string artist, string song_id) {
            stop();
            
            current_title = title;
            current_artist = artist;
            current_song_id = song_id;
            
            try {
                // Create a temporary file to store the downloaded content
                temp_file = File.new_tmp("ambersonic-XXXXXX.mp3", out temp_stream);
                
                // Start the download
                var message = new Soup.Message("GET", stream_url);
                session.send_async.begin(message, Priority.DEFAULT, cancellable, (obj, res) => {
                    try {
                        input_stream = session.send_async.end(res);
                        
                        // Get content length if available
                        var headers = message.get_response_headers();
                        var length_header = headers.get_content_length();
                        if (length_header > 0) {
                            content_length = length_header;
                        }
                        
                        // Start downloading the content
                        buffer_data.begin();
                        
                        // Update buffering progress
                        buffer_timer_id = Timeout.add(500, () => {
                            if (content_length > 0) {
                                buffer_progress((double)bytes_received / content_length);
                            }
                            return !download_completed;
                        });
                        
                        // Play after we've buffered some data (2 seconds)
                        Timeout.add(2000, () => {
                            start_playback();
                            return false;
                        });
                        
                    } catch (Error e) {
                        warning("Error loading audio stream: %s", e.message);
                    }
                });
                
            } catch (Error e) {
                warning("Error creating temporary file: %s", e.message);
            }
        }
        
        private async void buffer_data() {
            try {
                var output_stream = temp_stream.output_stream;
                uint8[] buffer = new uint8[8192];
                
                while (true) {
                    var size = yield input_stream.read_async(buffer);
                    if (size <= 0) {
                        download_completed = true;
                        break;
                    }
                    
                    yield output_stream.write_async(buffer[0:size]);
                    bytes_received += size;
                }
                
                yield output_stream.close_async();
                
            } catch (Error e) {
                if (!(e is IOError.CANCELLED)) {
                    warning("Error buffering audio data: %s", e.message);
                }
            }
        }
        
        private void start_playback() {
            try {
                // Ensure temp file is ready
                if (temp_file == null) {
                    warning("No file available for playback");
                    return;
                }
                
                // Setup properties for playback
                Canberra.Proplist props;
                Canberra.Proplist.create(out props);

                props.sets(Canberra.PROP_MEDIA_FILENAME, temp_file.get_path());
                props.sets(Canberra.PROP_MEDIA_NAME, current_title);
                props.sets(Canberra.PROP_MEDIA_ARTIST, current_artist);
                
                context.cancel(0);

                // Start the new playback
                context.play_full(0, props, (context, id, code) => {
                    if (code < 0) {
                        warning("Failed to play audio: %s", Canberra.strerror(code));
                        is_playing = false;
                        playback_stopped();
                    }
                });
                
                is_playing = true;
                playback_started();
                track_changed(current_title, current_artist);
                
                // Update position every second
                position_timer_id = Timeout.add(1000, () => {
                    if (is_playing) {
                        position += 1000; // Increment by 1 second
                        position_changed(position, duration);
                        return true;
                    }
                    return false;
                });
                
            } catch (Error e) {
                warning("Error starting playback: %s", e.message);
                is_playing = false;
                playback_stopped();
            }
        }
        
        public void pause() {
            if (is_playing) {
                context.cancel(0); // Cancel the current playback
                is_playing = false;
                playback_paused();
                
                if (position_timer_id > 0) {
                    Source.remove(position_timer_id);
                    position_timer_id = 0;
                }
            }
        }
        
        public void resume() {
            if (!is_playing && temp_file != null) {
                // Re-start playback from the current position
                start_playback();
            }
        }
        
        public void stop() {
            // Cancel any ongoing downloads
            cancellable.cancel();
            
            // Create a new cancellable for future operations
            cancellable = new Cancellable();
            
            // Stop timers
            if (position_timer_id > 0) {
                Source.remove(position_timer_id);
                position_timer_id = 0;
            }
            
            if (buffer_timer_id > 0) {
                Source.remove(buffer_timer_id);
                buffer_timer_id = 0;
            }
            
            // Stop playback
            if (is_playing) {
                context.cancel(0);
                is_playing = false;
                playback_stopped();
            }
            
            // Reset state
            position = 0;
            bytes_received = 0;
            content_length = 0;
            download_completed = false;
            
            // Clean up temp file
            try {
                if (input_stream != null) {
                    input_stream.close();
                    input_stream = null;
                }
                
                if (temp_stream != null) {
                    temp_stream.close();
                    temp_stream = null;
                }
                
                if (temp_file != null) {
                    temp_file.delete();
                    temp_file = null;
                }
            } catch (Error e) {
                warning("Error cleaning up audio resources: %s", e.message);
            }
        }
        
        public void seek(uint64 position_ms) {
            // Note: Simple seeking not supported in this implementation
            // Would require more complex audio library integration
            warning("Seeking not implemented in this player");
        }
        
        public void set_duration(uint64 duration_ms) {
            this.duration = duration_ms;
        }
        
        // Clean up when the object is destroyed
        ~AudioPlayer() {
            stop();
        }
    }
}