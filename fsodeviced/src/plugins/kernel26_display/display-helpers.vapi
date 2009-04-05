namespace DisplayHelpers {
	[CCode (cname = "fb_set_power")]
	public void set_fb (bool enable, int fd);
}
