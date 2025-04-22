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
}