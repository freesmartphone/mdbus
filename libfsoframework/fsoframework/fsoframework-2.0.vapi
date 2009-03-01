/* fsoframework-2.0.vapi generated by valac, do not modify. */

[CCode (cprefix = "FsoFramework", lower_case_cprefix = "fso_framework_")]
namespace FsoFramework {
	[CCode (cheader_filename = "fsoframework/smartkeyfile.h")]
	public class SmartKeyFile : GLib.Object {
		public bool boolValue (string section, string key, bool defaultvalue);
		public int intValue (string section, string key, int defaultvalue);
		public bool loadFromFile (string filename);
		public SmartKeyFile ();
		public string stringValue (string section, string key, string defaultvalue);
	}
	[CCode (cheader_filename = "fsoframework/common.h")]
	public static FsoFramework.SmartKeyFile MasterKeyFile ();
}
