using Strings.Audio;

namespace Strings {
    public class Config {
        [CCode (cname="GETTEXT_PACKAGE", cprefix = "", cheader_filename = "config.h")]
        public extern const string GETTEXT_PACKAGE;

        [CCode (cname="APPLICATION_ID", cprefix = "", cheader_filename = "config.h")]
        public extern const string APPLICATION_ID;

        protected static Config _instance;

        public static Config instance {
            get {
                if (_instance == null) { _instance = new Config (); }
                return _instance;
            }
        }

        protected Config () {
            scale = new Tuning.StandardConcertScale ();
            automatic_tuning = true;
        }

        public Tuning.Scale scale { get; set; }

        public bool automatic_tuning { get; set; }
    }
}