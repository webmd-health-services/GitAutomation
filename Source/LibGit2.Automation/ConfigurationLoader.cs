using LibGit2Sharp;

namespace LibGit2.Automation
{
	public static class ConfigurationLoader
	{
		public static Configuration Load()
		{
			return Configuration.BuildFrom(null, null);
		}
	}
}
