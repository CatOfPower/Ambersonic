public class Ambersonic.Api {
    private static string generate_salt(int length = 6) {
        const string CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
        var builder = new StringBuilder ();

        for (int i = 0; i < length; i++) {
            int index = Random.int_range (0, CHARS.length);
            builder.append_c (CHARS[index]);
        }
        return builder.str;
    }

    public static string generate_password_hash(string password) {
        var salt = generate_salt ();
        var hash = Checksum.compute_for_string (ChecksumType.MD5, password + salt);
        return hash + ":" + salt;
    }

    public static string method_address(string method) {
        var settings = new Settings ("cat.of.power.Ambersonic");
        var address = settings.get_string ("address");
        var username = settings.get_string ("username");
        var password = settings.get_string ("password");

        var password_with_salt = generate_password_hash (password);
        var hash = password_with_salt.split (":")[0];
        var salt = password_with_salt.split (":")[1];

        return address + "/rest/%s?v=1.16.1&c=ambersonic&u=%s&t=%s&s=%s".printf (method, username, hash, salt);
    }

    public static Xml.Doc* get (string method, string options) {
        var settings = new Settings ("cat.of.power.Ambersonic");

        var address = settings.get_string ("address");
        var username = settings.get_string ("username");
        var password = settings.get_string ("password");

        // Generate password hash and extract the hash and salt
        var password_with_salt = generate_password_hash (password);
        var parts = password_with_salt.split (":");
        if (parts.length != 2) {
            stderr.printf ("Invalid password hash format.\n");
        }
        var hash = parts[0];
        var salt = parts[1];

        // Create the url according to the required format.
        // Note: It is advisable to URL-encode parameters in real-world scenarios.
        var url = address + "/rest/%s?v=1.16.1&c=ambersonic&u=%s&t=%s&s=%s".printf (
            method,
            username,
            hash,
            salt
        );

        if (options != null) {
            url += "&" + options;
        }

        // Create the GET request.
        var request = new Soup.Message ("GET", url);

        // Create a session and send the request.
        var session = new Soup.Session ();

        // Send the request using session.send()
        var input_stream = session.send (request, null);
        var data_input_stream = new DataInputStream (input_stream);
        var response_body = new StringBuilder ();
        string? line;
        
        while ((line = data_input_stream.read_line ()) != null) {
            response_body.append (line);
        }

        var xml = Xml.Parser.parse_memory(response_body.str, response_body.str.length);

        if (xml == null) {
            stderr.printf ("Failed to parse XML response.\n");
            return null;
        }

        unowned Xml.Doc xml_doc = xml;
        return xml_doc;
    }

    public static int check_connection () {
        var connected = false;
        var authorised = false;

        unowned Xml.Doc test = Ambersonic.Api.get ("ping", "");
        unowned Xml.Node root = test.get_root_element ();
        
        if (root != null) {
            var status = root.get_prop ("status");

            if (status == "ok") {
                connected = true;
                authorised = true;
            } else if (status == "failed") {
                connected = true;
                authorised = false;
            }
        }

        if (connected) {
            if (authorised) {
                return 1; // Connection successful
            } else {
                return 2; // Incorrect username or password
            }
        } else {
            return 0; // Connection failed
        }
    }

    public static Gdk.Pixbuf get_album_cover (string cover_id) {
        var album_cover_url = Ambersonic.Api.method_address ("getCoverArt") + "&size=300&square=true&id=" + cover_id;

        var file = File.new_for_uri (album_cover_url);
        var input_stream = file.read ();
        var pixbuf = new Gdk.Pixbuf.from_stream (input_stream);
        pixbuf = pixbuf.scale_simple (100, 100, Gdk.InterpType.BILINEAR);
        return pixbuf;
    }

    public static Xml.Node get_album_list (string type) {
        unowned Xml.Doc response = Ambersonic.Api.get ("getAlbumList", "type=%s".printf (type));
        unowned Xml.Node root = response.get_root_element ();
        var album_list = root.get_last_child ();
        return album_list;
    }

    public static Xml.Node get_album (string id) {
        unowned Xml.Doc response = Ambersonic.Api.get ("getAlbum", "id=%s".printf (id));
        unowned Xml.Node root = response.get_root_element ();
        var album = root.get_last_child ();
        return album;
    }
    
    // Music folders
    public static Xml.Node get_music_folders () {
        unowned Xml.Doc response = Ambersonic.Api.get ("getMusicFolders", "");
        unowned Xml.Node root = response.get_root_element ();
        var music_folders = root.get_last_child ();
        return music_folders;
    }
    
    // Index navigation
    public static Xml.Node get_indexes (string? music_folder_id = null) {
        string options = "";
        if (music_folder_id != null) {
            options = "musicFolderId=%s".printf (music_folder_id);
        }
        
        unowned Xml.Doc response = Ambersonic.Api.get ("getIndexes", options);
        unowned Xml.Node root = response.get_root_element ();
        var indexes = root.get_last_child ();
        return indexes;
    }
    
    public static Xml.Node get_music_directory (string id) {
        unowned Xml.Doc response = Ambersonic.Api.get ("getMusicDirectory", "id=%s".printf (id));
        unowned Xml.Node root = response.get_root_element ();
        var directory = root.get_last_child ();
        return directory;
    }
    
    // Genre methods
    public static Xml.Node get_genres () {
        unowned Xml.Doc response = Ambersonic.Api.get ("getGenres", "");
        unowned Xml.Node root = response.get_root_element ();
        var genres = root.get_last_child ();
        return genres;
    }
    
    public static Xml.Node get_songs_by_genre (string genre, int count = 50, int offset = 0, string? music_folder_id = null) {
        var options_builder = new StringBuilder ();
        options_builder.append ("genre=%s&count=%d&offset=%d".printf (genre, count, offset));
        
        if (music_folder_id != null) {
            options_builder.append ("&musicFolderId=%s".printf (music_folder_id));
        }
        
        unowned Xml.Doc response = Ambersonic.Api.get ("getSongsByGenre", options_builder.str);
        unowned Xml.Node root = response.get_root_element ();
        var songs_by_genre = root.get_last_child ();
        return songs_by_genre;
    }
    
    // Artist methods
    public static Xml.Node get_artists (string? music_folder_id = null) {
        string options = "";
        if (music_folder_id != null) {
            options = "musicFolderId=%s".printf (music_folder_id);
        }
        
        unowned Xml.Doc response = Ambersonic.Api.get ("getArtists", options);
        unowned Xml.Node root = response.get_root_element ();
        var artists = root.get_last_child ();
        return artists;
    }
    
    public static Xml.Node get_artist (string id) {
        unowned Xml.Doc response = Ambersonic.Api.get ("getArtist", "id=%s".printf (id));
        unowned Xml.Node root = response.get_root_element ();
        var artist = root.get_last_child ();
        return artist;
    }
    
    public static Xml.Node get_artist_info2 (string id, int count = 20, bool include_not_present = false) {
        var options = "id=%s&count=%d&includeNotPresent=%s".printf (
            id, 
            count, 
            include_not_present ? "true" : "false"
        );
        
        unowned Xml.Doc response = Ambersonic.Api.get ("getArtistInfo2", options);
        unowned Xml.Node root = response.get_root_element ();
        var artist_info = root.get_last_child ();
        return artist_info;
    }
    
    // Album methods
    public static Xml.Node get_album_list2 (string type, int size = 50, int offset = 0, string? from_year = null, string? to_year = null, string? genre = null, string? music_folder_id = null) {
        var options_builder = new StringBuilder ();
        options_builder.append ("type=%s&size=%d&offset=%d".printf (type, size, offset));
        
        if (from_year != null && to_year != null) {
            options_builder.append ("&fromYear=%s&toYear=%s".printf (from_year, to_year));
        }
        
        if (genre != null) {
            options_builder.append ("&genre=%s".printf (genre));
        }
        
        if (music_folder_id != null) {
            options_builder.append ("&musicFolderId=%s".printf (music_folder_id));
        }
        
        unowned Xml.Doc response = Ambersonic.Api.get ("getAlbumList2", options_builder.str);
        unowned Xml.Node root = response.get_root_element ();
        var album_list = root.get_last_child ();
        return album_list;
    }
    
    public static Xml.Node get_album_info2 (string id) {
        unowned Xml.Doc response = Ambersonic.Api.get ("getAlbumInfo2", "id=%s".printf (id));
        unowned Xml.Node root = response.get_root_element ();
        var album_info = root.get_last_child ();
        return album_info;
    }
    
    // Song methods
    public static Xml.Node get_song (string id) {
        unowned Xml.Doc response = Ambersonic.Api.get ("getSong", "id=%s".printf (id));
        unowned Xml.Node root = response.get_root_element ();
        var song = root.get_last_child ();
        return song;
    }
    
    public static Xml.Node get_random_songs (int size = 50, string? genre = null, string? from_year = null, string? to_year = null, string? music_folder_id = null) {
        var options_builder = new StringBuilder ();
        options_builder.append ("size=%d".printf (size));
        
        if (genre != null) {
            options_builder.append ("&genre=%s".printf (genre));
        }
        
        if (from_year != null) {
            options_builder.append ("&fromYear=%s".printf (from_year));
        }
        
        if (to_year != null) {
            options_builder.append ("&toYear=%s".printf (to_year));
        }
        
        if (music_folder_id != null) {
            options_builder.append ("&musicFolderId=%s".printf (music_folder_id));
        }
        
        unowned Xml.Doc response = Ambersonic.Api.get ("getRandomSongs", options_builder.str);
        unowned Xml.Node root = response.get_root_element ();
        var random_songs = root.get_last_child ();
        return random_songs;
    }
    
    public static Xml.Node get_similar_songs2 (string id, int count = 50) {
        unowned Xml.Doc response = Ambersonic.Api.get ("getSimilarSongs2", "id=%s&count=%d".printf (id, count));
        unowned Xml.Node root = response.get_root_element ();
        var similar_songs = root.get_last_child ();
        return similar_songs;
    }
    
    public static Xml.Node get_top_songs (string artist, int count = 50) {
        unowned Xml.Doc response = Ambersonic.Api.get ("getTopSongs", "artist=%s&count=%d".printf (artist, count));
        unowned Xml.Node root = response.get_root_element ();
        var top_songs = root.get_last_child ();
        return top_songs;
    }
    
    // Video methods
    public static Xml.Node get_videos () {
        unowned Xml.Doc response = Ambersonic.Api.get ("getVideos", "");
        unowned Xml.Node root = response.get_root_element ();
        var videos = root.get_last_child ();
        return videos;
    }
    
    public static Xml.Node get_video_info (string id) {
        unowned Xml.Doc response = Ambersonic.Api.get ("getVideoInfo", "id=%s".printf (id));
        unowned Xml.Node root = response.get_root_element ();
        var video_info = root.get_last_child ();
        return video_info;
    }
    
    // Search methods
    public static Xml.Node search3 (string query, int artist_count = 20, int artist_offset = 0, int album_count = 20, int album_offset = 0, int song_count = 20, int song_offset = 0, string? music_folder_id = null) {
        var options_builder = new StringBuilder ();
        options_builder.append ("query=%s&artistCount=%d&artistOffset=%d&albumCount=%d&albumOffset=%d&songCount=%d&songOffset=%d".printf (
            query, artist_count, artist_offset, album_count, album_offset, song_count, song_offset
        ));
        
        if (music_folder_id != null) {
            options_builder.append ("&musicFolderId=%s".printf (music_folder_id));
        }
        
        unowned Xml.Doc response = Ambersonic.Api.get ("search3", options_builder.str);
        unowned Xml.Node root = response.get_root_element ();
        var search_result = root.get_last_child ();
        return search_result;
    }
    
    // Now playing
    public static Xml.Node get_now_playing () {
        unowned Xml.Doc response = Ambersonic.Api.get ("getNowPlaying", "");
        unowned Xml.Node root = response.get_root_element ();
        var now_playing = root.get_last_child ();
        return now_playing;
    }
    
    // Starred items
    public static Xml.Node get_starred2 (string? music_folder_id = null) {
        string options = "";
        if (music_folder_id != null) {
            options = "musicFolderId=%s".printf (music_folder_id);
        }
        
        unowned Xml.Doc response = Ambersonic.Api.get ("getStarred2", options);
        unowned Xml.Node root = response.get_root_element ();
        var starred = root.get_last_child ();
        return starred;
    }
    
    public static bool star (string[]? ids = null, string[]? album_ids = null, string[]? artist_ids = null) {
        var options_builder = new StringBuilder ();
        bool has_params = false;
        
        if (ids != null && ids.length > 0) {
            foreach (string id in ids) {
                if (has_params) {
                    options_builder.append ("&");
                }
                options_builder.append ("id=%s".printf (id));
                has_params = true;
            }
        }
        
        if (album_ids != null && album_ids.length > 0) {
            foreach (string album_id in album_ids) {
                if (has_params) {
                    options_builder.append ("&");
                }
                options_builder.append ("albumId=%s".printf (album_id));
                has_params = true;
            }
        }
        
        if (artist_ids != null && artist_ids.length > 0) {
            foreach (string artist_id in artist_ids) {
                if (has_params) {
                    options_builder.append ("&");
                }
                options_builder.append ("artistId=%s".printf (artist_id));
                has_params = true;
            }
        }
        
        if (!has_params) {
            return false;
        }
        
        unowned Xml.Doc response = Ambersonic.Api.get ("star", options_builder.str);
        unowned Xml.Node root = response.get_root_element ();
        return root.get_prop ("status") == "ok";
    }
    
    public static bool unstar (string[]? ids = null, string[]? album_ids = null, string[]? artist_ids = null) {
        var options_builder = new StringBuilder ();
        bool has_params = false;
        
        if (ids != null && ids.length > 0) {
            foreach (string id in ids) {
                if (has_params) {
                    options_builder.append ("&");
                }
                options_builder.append ("id=%s".printf (id));
                has_params = true;
            }
        }
        
        if (album_ids != null && album_ids.length > 0) {
            foreach (string album_id in album_ids) {
                if (has_params) {
                    options_builder.append ("&");
                }
                options_builder.append ("albumId=%s".printf (album_id));
                has_params = true;
            }
        }
        
        if (artist_ids != null && artist_ids.length > 0) {
            foreach (string artist_id in artist_ids) {
                if (has_params) {
                    options_builder.append ("&");
                }
                options_builder.append ("artistId=%s".printf (artist_id));
                has_params = true;
            }
        }
        
        if (!has_params) {
            return false;
        }
        
        unowned Xml.Doc response = Ambersonic.Api.get ("unstar", options_builder.str);
        unowned Xml.Node root = response.get_root_element ();
        return root.get_prop ("status") == "ok";
    }
    
    // Playlist methods
    public static Xml.Node get_playlists (string? username = null) {
        string options = "";
        if (username != null) {
            options = "username=%s".printf (username);
        }
        
        unowned Xml.Doc response = Ambersonic.Api.get ("getPlaylists", options);
        unowned Xml.Node root = response.get_root_element ();
        var playlists = root.get_last_child ();
        return playlists;
    }
    
    public static Xml.Node get_playlist (string id) {
        unowned Xml.Doc response = Ambersonic.Api.get ("getPlaylist", "id=%s".printf (id));
        unowned Xml.Node root = response.get_root_element ();
        var playlist = root.get_last_child ();
        return playlist;
    }
    
    public static Xml.Node create_playlist (string? playlist_id = null, string? name = null, string[]? song_ids = null) {
        var options_builder = new StringBuilder ();
        
        if (playlist_id != null) {
            options_builder.append ("playlistId=%s".printf (playlist_id));
        }
        
        if (name != null) {
            if (options_builder.len > 0) {
                options_builder.append ("&");
            }
            options_builder.append ("name=%s".printf (name));
        }
        
        if (song_ids != null && song_ids.length > 0) {
            foreach (string song_id in song_ids) {
                if (options_builder.len > 0) {
                    options_builder.append ("&");
                }
                options_builder.append ("songId=%s".printf (song_id));
            }
        }
        
        unowned Xml.Doc response = Ambersonic.Api.get ("createPlaylist", options_builder.str);
        unowned Xml.Node root = response.get_root_element ();
        // Since Subsonic 1.14.0, it returns the created/updated playlist
        var playlist = root.get_last_child ();
        return playlist;
    }
    
    public static bool update_playlist (string playlist_id, string? name = null, string? comment = null, bool? is_public = null, string[]? song_ids_to_add = null, int[]? song_indexes_to_remove = null) {
        var options_builder = new StringBuilder ();
        options_builder.append ("playlistId=%s".printf (playlist_id));
        
        if (name != null) {
            options_builder.append ("&name=%s".printf (name));
        }
        
        if (comment != null) {
            options_builder.append ("&comment=%s".printf (comment));
        }
        
        if (is_public != null) {
            options_builder.append ("&public=%s".printf (is_public ? "true" : "false"));
        }
        
        if (song_ids_to_add != null && song_ids_to_add.length > 0) {
            foreach (string song_id in song_ids_to_add) {
                options_builder.append ("&songIdToAdd=%s".printf (song_id));
            }
        }
        
        if (song_indexes_to_remove != null && song_indexes_to_remove.length > 0) {
            foreach (int index in song_indexes_to_remove) {
                options_builder.append ("&songIndexToRemove=%d".printf (index));
            }
        }
        
        unowned Xml.Doc response = Ambersonic.Api.get ("updatePlaylist", options_builder.str);
        unowned Xml.Node root = response.get_root_element ();
        return root.get_prop ("status") == "ok";
    }
    
    public static bool delete_playlist (string id) {
        unowned Xml.Doc response = Ambersonic.Api.get ("deletePlaylist", "id=%s".printf (id));
        unowned Xml.Node root = response.get_root_element ();
        return root.get_prop ("status") == "ok";
    }
    
    // Streaming and downloading
    public static string get_stream_url (string id, int? max_bit_rate = null, string? format = null, int? time_offset = null, string? size = null, bool? estimate_content_length = null, bool? converted = null) {
        var options_builder = new StringBuilder ();
        options_builder.append ("id=%s".printf (id));
        
        if (max_bit_rate != null) {
            options_builder.append ("&maxBitRate=%d".printf (max_bit_rate));
        }
        
        if (format != null) {
            options_builder.append ("&format=%s".printf (format));
        }
        
        if (time_offset != null) {
            options_builder.append ("&timeOffset=%d".printf (time_offset));
        }
        
        if (size != null) {
            options_builder.append ("&size=%s".printf (size));
        }
        
        if (estimate_content_length != null) {
            options_builder.append ("&estimateContentLength=%s".printf (estimate_content_length ? "true" : "false"));
        }
        
        if (converted != null) {
            options_builder.append ("&converted=%s".printf (converted ? "true" : "false"));
        }
        
        return method_address ("stream") + "&" + options_builder.str;
    }
    
    public static string get_download_url (string id) {
        return method_address ("download") + "&id=" + id;
    }
    
    public static string get_hls_url (string id, int[]? bit_rates = null, string? audio_track = null) {
        var options_builder = new StringBuilder ();
        options_builder.append ("id=%s".printf (id));
        
        if (bit_rates != null && bit_rates.length > 0) {
            foreach (int bit_rate in bit_rates) {
                options_builder.append ("&bitRate=%d".printf (bit_rate));
            }
        }
        
        if (audio_track != null) {
            options_builder.append ("&audioTrack=%s".printf (audio_track));
        }
        
        return method_address ("hls.m3u8") + "&" + options_builder.str;
    }
    
    public static string get_captions_url (string id, string? format = null) {
        var options_builder = new StringBuilder ();
        options_builder.append ("id=%s".printf (id));
        
        if (format != null) {
            options_builder.append ("&format=%s".printf (format));
        }
        
        return method_address ("getCaptions") + "&" + options_builder.str;
    }
    
    public static string get_cover_art_url (string id, int? size = null) {
        var options_builder = new StringBuilder ();
        options_builder.append ("id=%s".printf (id));
        
        if (size != null) {
            options_builder.append ("&size=%d".printf (size));
        }
        
        return method_address ("getCoverArt") + "&" + options_builder.str;
    }
    
    // Lyrics
    public static Xml.Node get_lyrics (string? artist = null, string? title = null) {
        var options_builder = new StringBuilder ();
        
        if (artist != null) {
            options_builder.append ("artist=%s".printf (artist));
        }
        
        if (title != null) {
            if (options_builder.len > 0) {
                options_builder.append ("&");
            }
            options_builder.append ("title=%s".printf (title));
        }
        
        unowned Xml.Doc response = Ambersonic.Api.get ("getLyrics", options_builder.str);
        unowned Xml.Node root = response.get_root_element ();
        var lyrics = root.get_last_child ();
        return lyrics;
    }
    
    // User methods
    public static Xml.Node get_user (string username) {
        unowned Xml.Doc response = Ambersonic.Api.get ("getUser", "username=%s".printf (username));
        unowned Xml.Node root = response.get_root_element ();
        var user = root.get_last_child ();
        return user;
    }
    
    public static Xml.Node get_users () {
        unowned Xml.Doc response = Ambersonic.Api.get ("getUsers", "");
        unowned Xml.Node root = response.get_root_element ();
        var users = root.get_last_child ();
        return users;
    }
    
    // Podcast methods
    public static Xml.Node get_podcasts (bool include_episodes = true, string? id = null) {
        var options_builder = new StringBuilder ();
        options_builder.append ("includeEpisodes=%s".printf (include_episodes ? "true" : "false"));
        
        if (id != null) {
            options_builder.append ("&id=%s".printf (id));
        }
        
        unowned Xml.Doc response = Ambersonic.Api.get ("getPodcasts", options_builder.str);
        unowned Xml.Node root = response.get_root_element ();
        var podcasts = root.get_last_child ();
        return podcasts;
    }
    
    public static Xml.Node get_newest_podcasts (int count = 20) {
        unowned Xml.Doc response = Ambersonic.Api.get ("getNewestPodcasts", "count=%d".printf (count));
        unowned Xml.Node root = response.get_root_element ();
        var newest_podcasts = root.get_last_child ();
        return newest_podcasts;
    }
    
    public static bool refresh_podcasts () {
        unowned Xml.Doc response = Ambersonic.Api.get ("refreshPodcasts", "");
        unowned Xml.Node root = response.get_root_element ();
        return root.get_prop ("status") == "ok";
    }
    
    public static bool create_podcast_channel (string url) {
        unowned Xml.Doc response = Ambersonic.Api.get ("createPodcastChannel", "url=%s".printf (url));
        unowned Xml.Node root = response.get_root_element ();
        return root.get_prop ("status") == "ok";
    }
    
    public static bool delete_podcast_channel (string id) {
        unowned Xml.Doc response = Ambersonic.Api.get ("deletePodcastChannel", "id=%s".printf (id));
        unowned Xml.Node root = response.get_root_element ();
        return root.get_prop ("status") == "ok";
    }
    
    public static bool delete_podcast_episode (string id) {
        unowned Xml.Doc response = Ambersonic.Api.get ("deletePodcastEpisode", "id=%s".printf (id));
        unowned Xml.Node root = response.get_root_element ();
        return root.get_prop ("status") == "ok";
    }
    
    public static bool download_podcast_episode (string id) {
        unowned Xml.Doc response = Ambersonic.Api.get ("downloadPodcastEpisode", "id=%s".printf (id));
        unowned Xml.Node root = response.get_root_element ();
        return root.get_prop ("status") == "ok";
    }
    
    // Bookmark methods
    public static Xml.Node get_bookmarks () {
        unowned Xml.Doc response = Ambersonic.Api.get ("getBookmarks", "");
        unowned Xml.Node root = response.get_root_element ();
        var bookmarks = root.get_last_child ();
        return bookmarks;
    }
    
    public static bool create_bookmark (string id, int position, string? comment = null) {
        var options_builder = new StringBuilder ();
        options_builder.append ("id=%s&position=%d".printf (id, position));
        
        if (comment != null) {
            options_builder.append ("&comment=%s".printf (comment));
        }
        
        unowned Xml.Doc response = Ambersonic.Api.get ("createBookmark", options_builder.str);
        unowned Xml.Node root = response.get_root_element ();
        return root.get_prop ("status") == "ok";
    }

    public static bool delete_bookmark (string id) {
        unowned Xml.Doc response = Ambersonic.Api.get ("deleteBookmark", "id=%s".printf (id));
        unowned Xml.Node root = response.get_root_element ();
        return root.get_prop ("status") == "ok";
    }

    // Queue methods
    public static Xml.Node get_queue () {
        unowned Xml.Doc response = Ambersonic.Api.get ("getQueue", "");
        unowned Xml.Node root = response.get_root_element ();
        var queue = root.get_last_child ();
        return queue;
    }

    public static bool save_queue (bool? current = null, string? name = null) {
        var options_builder = new StringBuilder ();
        
        if (current != null) {
            options_builder.append ("current=%s".printf (current ? "true" : "false"));
        }
        
        if (name != null) {
            if (options_builder.len > 0) {
                options_builder.append ("&");
            }
            options_builder.append ("name=%s".printf (name));
        }
        
        unowned Xml.Doc response = Ambersonic.Api.get ("saveQueue", options_builder.str);
        unowned Xml.Node root = response.get_root_element ();
        return root.get_prop ("status") == "ok";
    }
}