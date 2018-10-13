using LibGit2Sharp;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Git.Automation
{
    public static class ConfigurationExtensions
    {
        public static ConfigurationEntry<string> GetString(this Configuration configuration, string[] keyParts)
        {
            return configuration.Get<string>(keyParts);

        }

        public static ConfigurationEntry<string> GetString(this Configuration configuration, string firstKeyPart, string secondKeyPart, string thirdKeyPart)
        {
            return configuration.Get<string>(firstKeyPart, secondKeyPart, thirdKeyPart);
        }

        public static ConfigurationEntry<string> GetString(this Configuration configuration, string key)
        {
            return configuration.Get<string>(key);
        }

        public static ConfigurationEntry<string> GetString(this Configuration configuration, string key, ConfigurationLevel level)
        {
            return configuration.Get<string>(key, level);
        }
    }
}
