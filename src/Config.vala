[CCode (cprefix = "", cheader_filename = "config.h")]
namespace Strings.Config {
    [CCode (cname="GETTEXT_PACKAGE")]
    public extern const string GETTEXT_PACKAGE;

    [CCode (cname="APPLICATION_ID")]
    public extern const string APPLICATION_ID;
}